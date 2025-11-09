# TODO: too many divisions but no zero check (LoL)
use std log


export def "ffprobe-nu" [input: path] {
  ffprobe -v quiet -print_format json -show_format -show_streams $input | from json
} 

export def "compress-video" [src: string, target: string] {
  let duration_sec = (ffprobe-nu $src | get -o format.duration | default "60" | into int)
  let size = (ls $src | get size | first)
  let started = (date now)
  mut state = 0
  print $"Original size: (ansi red)($size)(ansi reset)"
  print $"Starting the process"
  log debug $"Starting compression of ($src) to ($target), duration: ($duration_sec) seconds, size: ($size)"
  for line in (ffmpeg -hwaccel cuda -stats -y -i $src -c:v hevc_nvenc -preset p7 -rc vbr -cq 25 -b:v 2M -maxrate 5M -bufsize 10M -c:a aac -b:a 128k -movflags +faststart -progress pipe:1 $target out+err>| lines) {
    log debug $"Processing line: ($line)"
    if $line =~ '^out_time_ms' {
      log debug $"Found progress line: ($line)"
      let out_str = ($line | str replace 'out_time_ms=' '')
      let current_state = $state
      let beginning = $"\r(progress indicator $current_state) "
      $state = $state + 1
      if $out_str !~ '\d+' {
        return $beginning
      }
      let out_ms = ($out_str | into int)
      let out_sec = ($out_ms / 1_000_000)
      let percent = ($out_sec / $duration_sec) 
      let now = (date now)
      let elapsed = ($now - $started)
      let remain = ($elapsed / $percent) - $elapsed
      let target_size = (ls $target | first | get size)
      let final_size = ($target_size / $percent)
      let final_size_mib = ($final_size  / 1_048_576 | into int)
      let elapsed_str = ($elapsed | into string | str replace --regex "(?!.+sec) .*" "")
      let remain_str = ($remain | into string | str replace --regex "(?!.+sec) .*" "")
      let width = ((term size | get columns) * 0.8 | into int)
      log debug $"Progress: ($percent), Elapsed: ($elapsed_str), Remaining: ($remain_str), Final Size: ($final_size_mib) MiB"
      let progress_line = $"($beginning)[(progress bar $percent --width $width | ansi gradient --fgstart '0xD03030' --fgend '0x00FF00')] ($percent * 100 | math round --precision 2)%"
      let info_line = $"elapsed: (ansi green_bold)($elapsed_str)(ansi reset) remaining: (ansi green_bold)($remain_str)(ansi reset), final size: (ansi green_bold)~($final_size_mib) MiB(ansi reset) reduction: (ansi green_bold)~(((1 - $final_size / $size) * 100) | math round --precision 2)%(ansi reset)"
      print -n $"(ansi -e "1A")(ansi -e "2K")\r($info_line)\n(ansi -e "2K")($progress_line)"
    } 
  }
  let now = (date now)
  let final_size = (ls $target | first | get size)
  log debug $"Compression completed, final size: ($final_size), original size: ($size)"
  print $"\nCompression (ansi green_bold)completed(ansi reset) in (ansi green_bold)($now - $started)(ansi reset).
  Started At: (ansi green_bold)($started)(ansi reset) Finished: (ansi green_bold)($now)(ansi reset)
  Original Size:(ansi red_bold)($size)(ansi reset) Final size: (ansi green_bold)($final_size)(ansi reset), (ansi green_bold)(($final_size / $size * 100) | math round --precision 2)%(ansi reset) of original size"
}

export def "compress-video-cpu" [src: string, target: string] {
  let duration_sec = (ffprobe-nu $src | get -o format.duration | default "60" | into int)
  let size = (ls $src | get size | first)
  let started = (date now)
  mut state = 0
  print $"Original size: (ansi red)($size)(ansi reset)"
  print $"Starting the process"
  log debug $"Starting compression of ($src) to ($target), duration: ($duration_sec) seconds, size: ($size)"
  for line in (ffmpeg -i $src -pix_fmt yuv420p -c:v libx265 -preset medium -crf 27 -c:a aac -b:a 96k -movflags +faststart -progress pipe:1 -y $target out+err>| lines) {
    log debug $"Processing line: ($line)"
    if $line =~ '^out_time_ms' {
      log debug $"Found progress line: ($line)"
      let out_str = ($line | str replace 'out_time_ms=' '')
      let current_state = $state
      let beginning = $"\r(progress indicator $current_state) "
      $state = $state + 1
      if $out_str !~ '\d+' {
        return $beginning
      }
      let out_ms = ($out_str | into int)
      let out_sec = ($out_ms / 1_000_000)
      let percent = ($out_sec / $duration_sec) 
      let now = (date now)
      let elapsed = ($now - $started)
      let remain = ($elapsed / $percent) - $elapsed
      let target_size = (ls $target | first | get size)
      let final_size = ($target_size / $percent)
      let final_size_mib = ($final_size  / 1_048_576 | into int)
      let elapsed_str = ($elapsed | into string | str replace --regex "(?!.+sec) .*" "")
      let remain_str = ($remain | into string | str replace --regex "(?!.+sec) .*" "")
      let width = ((term size | get columns) * 0.8 | into int)
      log debug $"Progress: ($percent), Elapsed: ($elapsed_str), Remaining: ($remain_str), Final Size: ($final_size_mib) MiB"
      let progress_line = $"($beginning)[(progress bar $percent --width $width | ansi gradient --fgstart '0xD03030' --fgend '0x00FF00')] ($percent * 100 | math round --precision 2)%"
      let info_line = $"elapsed: (ansi green_bold)($elapsed_str)(ansi reset) remaining: (ansi green_bold)($remain_str)(ansi reset), final size: (ansi green_bold)~($final_size_mib) MiB(ansi reset) reduction: (ansi green_bold)~(((1 - $final_size / $size) * 100) | math round --precision 2)%(ansi reset)"
      print -n $"(ansi -e "1A")(ansi -e "2K")\r($info_line)\n(ansi -e "2K")($progress_line)"
    } 
  }
  let now = (date now)
  let final_size = (ls $target | first | get size)
  log debug $"Compression completed, final size: ($final_size), original size: ($size)"
  print $"\nCompression (ansi green_bold)completed(ansi reset) in (ansi green_bold)($now - $started)(ansi reset).
  Started At: (ansi green_bold)($started)(ansi reset) Finished: (ansi green_bold)($now)(ansi reset)
  Original Size:(ansi red_bold)($size)(ansi reset) Final size: (ansi green_bold)($final_size)(ansi reset), (ansi green_bold)(($final_size / $size * 100) | math round --precision 2)%(ansi reset) of original size"
}

export def "compress-inplace" [
  test?: closure
] {
  
  let started = (date now)
  let size = (du --max-depth 0 | reduce --fold 0Mb {|it, acc| $acc + $it.physical})
  
  let default_test = { |file| true }
  let filter = if ($test == null) { $default_test } else { $test }
  let items = (
    ls
    | where type == "file"
    | where name !~ "^000."
    | select name size
    | where {|f| do $filter ($f | get name) }
  )
  if ($items | is-empty) {
    print "no file selected"
    return false
  }
  let predictedSize = (
    $items 
    | each {|it| $it.size * (1Mb / (ffprobe-nu $it.name | get format.bit_rate | into filesize)) }
    | reduce --fold 0Mb {|it, acc| $acc + $it }
  )
  let totalSize = (
    $items 
    | get size
    | reduce --fold 0Mb {|it, acc| $acc + $it }
  )
  print $"Current size: (ansi red_bold)( $totalSize)(ansi reset)"
  print $"Predicted size after conversion: (ansi green_bold)( $predictedSize)(ansi reset)"
  mut index = 1
  let length = ($items | length)
 
  for full_src in ($items | get name) {
    let parsed = ($full_src | path parse)
    let temp_target = ($"000.compressing.($parsed.stem | str trim).($parsed.extension)")
    print $"($index)/($length) * Encoding (ansi green_bold)`($full_src)`(ansi reset)"
    $index = $index + 1
    retry { 
      compress-video-cpu $full_src $temp_target 
    }
    log debug $"Compression of ($full_src) to ($temp_target) finished, waiting for ffmpeg to unlock the temporary file"
    if (not (until unlocked $temp_target --timeout 10min --holder "ffmpeg.exe") ) {
      error make {msg: $"file ($temp_target) is locked by ffmpeg, cannot continue, please check if ffmpeg is running and try again", }
    }
    log debug $"ffmpeg unlocked the temporary file will proceed to switch temp file with original"
    retry --count 30 --sleep 5sec { 
      let src_length = (ffprobe-nu $full_src | get format.duration | into int)
      let final_length = (ffprobe-nu $temp_target | get format.duration | into int)
      # 30 sec tolerance
      if ($src_length - 30) >= $final_length {
        error make {msg: $"original file is longer than converted file, unacceptable, src: ($full_src), diff: ($src_length - $final_length)", }
      }
      log debug $"Final length: ($final_length), source length: ($src_length), difference: ($src_length - $final_length)"
      mv --force $temp_target $full_src
    }
  }

  let now = (date now)
  let final_size = (du --max-depth 0 | reduce --fold 0Mb {|it, acc| $acc + $it.physical})
  if ($size <= 1Mb) {
    print $"\nDirectory (ansi green_bold)completed(ansi reset) in (ansi green_bold)($now - $started)(ansi reset).
  Started At: (ansi green_bold)($started)(ansi reset) Finished: (ansi green_bold)($now)(ansi reset)"
    return true
  }
  print $"\nDirectory (ansi green_bold)completed(ansi reset) in (ansi green_bold)($now - $started)(ansi reset).
  Started At: (ansi green_bold)($started)(ansi reset) Finished: (ansi green_bold)($now)(ansi reset)
  Original Directory Size:(ansi red_bold)($size)(ansi reset) Final size: (ansi green_bold)($final_size)(ansi reset), (ansi green_bold)(($final_size / $size * 100) | math round --precision 2)%(ansi reset) of original size"
  return true
}

export def "compress-big-videos" [] {
  compress-inplace { |it|
    ((ls $it | get size | first) > 1gb) and ((ffprobe-nu $it | get format.bit_rate | into filesize) > 2Mb)
  }
}

export def "compress-big-videos-recurs" [] {
  let directories = (ls --full-paths --directory **/*/ | where type == "dir" | get name | append "./")
  let pwd = (pwd)
  for dir in $directories {
    cd $dir
    print $"Working directory: (ansi green_bold)($dir)(ansi reset)"
    compress-big-videos
    cd $pwd
  }
}

