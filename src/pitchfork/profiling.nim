import std/[times, monotimes, tables, strformat, strutils, algorithm]

when defined(profile):
  var timingData {.threadvar.}: Table[string, Duration]
  var timingCounts {.threadvar.}: Table[string, int]

template profile*(label: string, body: untyped) =
  ## Time a block of code when compiled with -d:profile
  when defined(profile):
    let start = getMonoTime()
    body
    let elapsed = getMonoTime() - start
    
    if label notin timingData:
      timingData[label] = DurationZero
      timingCounts[label] = 0
    
    timingData[label] += elapsed
    timingCounts[label] += 1
  else:
    # When not profiling, just execute the code with zero overhead
    body

proc printProfilingReport*() =
  ## Print timing report sorted by total time
  when defined(profile):
    if timingData.len == 0:
      echo "No timing data collected"
      return
    
    echo "\n=== Timing Report ==="
    echo &"""{"Label":<30} {"Total (ms)":>12} {"Count":>10} {"Avg (μs)":>12}"""
    echo "-".repeat(66)
    
    # Sort by total time descending
    var sortedPairs: seq[(string, Duration)]
    for label, duration in timingData.pairs:
      sortedPairs.add((label, duration))
    
    sortedPairs.sort do (a, b: (string, Duration)) -> int:
      # Sort by duration descending (b before a for reverse order)
      let diff = b[1].inNanoseconds - a[1].inNanoseconds
      if diff > 0: 1
      elif diff < 0: -1
      else: 0
    
    for (label, duration) in sortedPairs:
      let count = timingCounts[label]
      let totalMs = duration.inNanoseconds.float / 1_000_000.0
      let avgUs = duration.inNanoseconds.float / count.float / 1_000.0
      echo &"{label:<30} {totalMs:>12.3f} {count:>10} {avgUs:>12.3f}"
    
    # Print summary
    var totalTime = DurationZero
    for duration in timingData.values:
      totalTime += duration
    
    echo "" & "-".repeat(66)
    echo &"""{"TOTAL":<30} {totalTime.inNanoseconds.float / 1_000_000.0:>12.3f}"""
  else:
    discard
