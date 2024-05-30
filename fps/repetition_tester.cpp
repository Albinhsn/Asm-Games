#include "repetition_tester.h"
#include <cstdint>
#include <fcntl.h>
#include <immintrin.h> // AVX, AVX2, FMA, AVX-512
#include <stdio.h>
#include <sys/time.h>
#include <unistd.h>

#define ArrayCount(Array) (sizeof(Array) / sizeof((Array)[0]))

extern "C" void write_line(void *buffer, u32 color, u32 start_x, u32 start_y,
                           u32 end_x, u32 end_y, u32 buffer_width);

void set_pixel(char *buffer, u64 x, u64 y, u32 color, u64 width) {
  u64 index = (x + y * width) * 4;
  buffer[index] = color;
}
void write_line_c(void *buffer, u32 color, u32 start_x, u32 start_y, u32 end_x,
                  u32 end_y, u32 buffer_width) {

  bool steep = ABS((i64)(start_x - end_x)) < ABS((i64)(start_y - end_y));
  if (steep) {
    u64 tmp = start_x;
    start_x = start_y;
    start_y = tmp;

    tmp = end_x;
    end_x = end_y;
    end_y = tmp;
  }

  if (start_x > end_x) {
    u64 tmp = start_x;
    start_x = end_x;
    end_x = tmp;

    tmp = start_y;
    start_y = end_y;
    end_y = tmp;
  }

  i64 dx = end_x - start_x;
  i64 dy = 2 * (end_y - start_y);

  bool downwards = dy < 0;
  dy = downwards ? -dy : dy;

  i64 derror = 0;
  u64 y = start_y;
  for (u64 x = start_x; x < end_x; x++) {
    set_pixel((char *)buffer, steep ? y : x, steep ? x : y, color,
              buffer_width);
    derror += dy;
    if (derror > dx) {
      y = downwards ? y - 1 : y + 1;
      derror -= 2 * dx;
    }
  }
}

Profiler profiler;
u32 globalProfilerParentIndex = 0;
ProfileAnchor globalProfileAnchors[4096];

void initProfileBlock(ProfileBlock *block, char const *label_, u32 index_,
                      u64 byteCount) {
  block->parentIndex = globalProfilerParentIndex;

  block->index = index_;
  block->label = label_;

  ProfileAnchor *profile = globalProfileAnchors + block->index;
  block->oldElapsedInclusive = profile->elapsedInclusive;
  profile->processedByteCount += byteCount;

  globalProfilerParentIndex = block->index;
  block->startTime = ReadCPUTimer();
}
void exitProfileBlock(ProfileBlock *block) {
  u64 elapsed = ReadCPUTimer() - block->startTime;
  globalProfilerParentIndex = block->parentIndex;

  ProfileAnchor *parent = globalProfileAnchors + block->parentIndex;
  ProfileAnchor *profile = globalProfileAnchors + block->index;

  parent->elapsedExclusive -= elapsed;
  profile->elapsedExclusive += elapsed;
  profile->elapsedInclusive = block->oldElapsedInclusive + elapsed;
  ++profile->hitCount;

  profile->label = block->label;
}

static void PrintTimeElapsed(ProfileAnchor *Anchor, u64 timerFreq,
                             u64 TotalTSCElapsed) {

  f64 Percent = 100.0 * ((f64)Anchor->elapsedExclusive / (f64)TotalTSCElapsed);
  printf("  %s[%lu]: %lu (%.2f%%", Anchor->label, Anchor->hitCount,
         Anchor->elapsedExclusive, Percent);
  if (Anchor->elapsedInclusive != Anchor->elapsedExclusive) {
    f64 PercentWithChildren =
        100.0 * ((f64)Anchor->elapsedInclusive / (f64)TotalTSCElapsed);
    printf(", %.2f%% w/children", PercentWithChildren);
  }
  if (Anchor->processedByteCount) {
    f64 mb = 1024.0f * 1024.0f;
    f64 gb = mb * 1024.0f;

    f64 seconds = Anchor->elapsedInclusive / (f64)timerFreq;
    f64 bytesPerSecond = Anchor->processedByteCount / seconds;
    f64 mbProcessed = Anchor->processedByteCount / mb;
    f64 gbProcessed = bytesPerSecond / gb;

    printf(" %.3fmb at %.2fgb/s", mbProcessed, gbProcessed);
  }
  printf(")\n");
}
static u64 GetOSTimerFreq(void) { return 1000000; }

static u64 ReadOSTimer(void) {
  struct timeval Value;
  gettimeofday(&Value, 0);

  u64 Result = GetOSTimerFreq() * (u64)Value.tv_sec + (u64)Value.tv_usec;
  return Result;
}

u64 ReadCPUTimer(void) { return __rdtsc(); }

#define TIME_TO_WAIT 100

u64 EstimateCPUTimerFreq(void) {
  u64 OSFreq = GetOSTimerFreq();

  u64 CPUStart = ReadCPUTimer();
  u64 OSStart = ReadOSTimer();
  u64 OSElapsed = 0;
  u64 OSEnd = 0;
  u64 OSWaitTime = OSFreq * TIME_TO_WAIT / 1000;
  while (OSElapsed < OSWaitTime) {
    OSEnd = ReadOSTimer();
    OSElapsed = OSEnd - OSStart;
  }

  u64 CPUEnd = ReadCPUTimer();
  u64 CPUElapsed = CPUEnd - CPUStart;

  return OSFreq * CPUElapsed / OSElapsed;
}
#undef TIME_TO_WAIT

void initProfiler() { profiler.StartTSC = ReadCPUTimer(); }

void displayProfilingResult() {
  u64 endTime = ReadCPUTimer();
  u64 totalElapsed = endTime - profiler.StartTSC;
  u64 cpuFreq = EstimateCPUTimerFreq();

  printf("\nTotal time: %0.4fms (CPU freq %lu)\n",
         1000.0 * (f64)totalElapsed / (f64)cpuFreq, cpuFreq);
  for (u32 i = 0; i < ArrayCount(globalProfileAnchors); i++) {
    ProfileAnchor *profile = globalProfileAnchors + i;

    if (profile->elapsedInclusive) {
      PrintTimeElapsed(profile, cpuFreq, totalElapsed);
    }
  }
}

static f64 SecondsFromCPUTime(f64 CPUTime, u64 CPUTimerFreq) {
  f64 Result = 0.0;
  if (CPUTimerFreq) {
    Result = (CPUTime / (f64)CPUTimerFreq);
  }

  return Result;
}

static void PrintTime(char const *Label, f64 CPUTime, u64 CPUTimerFreq,
                      u64 ByteCount) {
  printf("%s: %.0f", Label, CPUTime);
  if (CPUTimerFreq) {
    f64 Seconds = SecondsFromCPUTime(CPUTime, CPUTimerFreq);
    printf(" (%fms)", 1000.0f * Seconds);

    if (ByteCount) {
      f64 Gigabyte = (1024.0f * 1024.0f * 1024.0f);
      f64 BestBandwidth = ByteCount / (Gigabyte * Seconds);
      printf(" %fgb/s", BestBandwidth);
    }
  }
}

static void PrintResults(RepetitionTestResults Results, u64 CPUTimerFreq,
                         u64 ByteCount) {
  PrintTime("Min", (f64)Results.minTime, CPUTimerFreq, ByteCount);
  printf("\n");

  PrintTime("Max", (f64)Results.maxTime, CPUTimerFreq, ByteCount);
  printf(" at %ld", Results.worstTest);
  printf("\n");

  if (Results.testCount) {
    PrintTime("Avg", (f64)Results.totalTime / (f64)Results.testCount,
              CPUTimerFreq, ByteCount);
    printf("\n");
  }
}
static void Error(RepetitionTester *tester, char const *Message) {
  tester->mode = TestMode_Error;
  fprintf(stderr, "ERROR: %s\n", Message);
}

static void NewTestWave(RepetitionTester *tester, u64 targetProcessedByteCount,
                        u64 CPUTimerFreq) {
  u32 SecondsToTry = 10;
  if (tester->mode == TestMode_Uninitialized) {
    tester->mode = TestMode_Testing;
    tester->targetProcessedByteCount = targetProcessedByteCount;
    tester->CPUTimerFreq = CPUTimerFreq;
    tester->printNewMinimums = true;
    tester->results.minTime = (u64)INT64_MAX;
  } else if (tester->mode == TestMode_Completed) {
    tester->mode = TestMode_Testing;

    if (tester->targetProcessedByteCount != targetProcessedByteCount) {
      Error(tester, "TargetProcessedByteCount changed");
    }

    if (tester->CPUTimerFreq != CPUTimerFreq) {
      Error(tester, "CPU frequency changed");
    }
  }

  tester->tryForTime = SecondsToTry * CPUTimerFreq;
  tester->testsStartedAt = ReadCPUTimer();
}

static inline void BeginTime(RepetitionTester *tester) {
  ++tester->openBlockCount;
  tester->timeAccumulatedOnThisTest -= ReadCPUTimer();
}

static inline void EndTime(RepetitionTester *tester) {
  ++tester->closeBlockCount;
  tester->timeAccumulatedOnThisTest += ReadCPUTimer();
}

static inline void CountBytes(RepetitionTester *tester, u64 ByteCount) {
  tester->bytesAccumulatedOnThisTest += ByteCount;
}

static bool IsTesting(RepetitionTester *tester) {
  if (tester->mode == TestMode_Testing) {
    u64 CurrentTime = ReadCPUTimer();

    if (tester->openBlockCount) // NOTE(casey): We don't count tests that had no
                                // timing blocks - we assume they took some
                                // other path
    {
      if (tester->openBlockCount != tester->closeBlockCount) {
        Error(tester, "Unbalanced BeginTime/EndTime");
      }

      if (tester->bytesAccumulatedOnThisTest !=
          tester->targetProcessedByteCount) {
        Error(tester, "Processed byte count mismatch");
      }

      if (tester->mode == TestMode_Testing) {
        RepetitionTestResults *results = &tester->results;
        u64 ElapsedTime = tester->timeAccumulatedOnThisTest;
        results->testCount += 1;
        results->totalTime += ElapsedTime;
        if (results->maxTime < ElapsedTime) {
          results->maxTime = ElapsedTime;
          results->worstTest = results->testCount - 1;
        }

        if (results->minTime > ElapsedTime) {
          results->minTime = ElapsedTime;
          PrintTime("Min", results->minTime, tester->CPUTimerFreq,
                    tester->bytesAccumulatedOnThisTest);
          printf("               \r");
          fflush(stdout);

          // NOTE(casey): Whenever we get a new minimum time, we reset the clock
          // to the full trial time
          tester->testsStartedAt = CurrentTime;
        }

        tester->openBlockCount = 0;
        tester->closeBlockCount = 0;
        tester->timeAccumulatedOnThisTest = 0;
        tester->bytesAccumulatedOnThisTest = 0;
      }
    }

    if ((CurrentTime - tester->testsStartedAt) > tester->tryForTime) {
      tester->mode = TestMode_Completed;

      printf("                                                          \r");
      PrintResults(tester->results, tester->CPUTimerFreq,
                   tester->targetProcessedByteCount);
    }
  }

  bool Result = (tester->mode == TestMode_Testing);
  return Result;
}

typedef void TestFunc(void *buffer, u32 color, u32 start_x, u32 start_y,
                      u32 end_x, u32 end_y, u32 buffer_width);

struct TestFunction {
  char const *Name;
  TestFunc *Func;
};
typedef struct TestFunction TestFunction;
TestFunction testFunctions[] = {
    {"asm", write_line},
    {"c", write_line_c},
};

int main() {

  u64 CPUTimerFreq = EstimateCPUTimerFreq();

  RepetitionTester testers[ArrayCount(testFunctions)] = {};
  u64 width = 620;
  u64 height = 480;
  void *buffer = malloc(4 * width * height);
  u32 color = 0xFFFFFFFF;
  u32 start_x = 100, start_y = 100, end_x = 275, end_y = 325;

  for (;;) {
    for (u32 funcIndex = 0; funcIndex < ArrayCount(testFunctions);
         ++funcIndex) {
      RepetitionTester *tester = &testers[funcIndex];
      TestFunction testFunc = testFunctions[funcIndex];

      printf("\n--- %s ---\n", testFunc.Name);
      long size = ArrayCount(testFunctions);
      NewTestWave(tester, size, CPUTimerFreq);
      while (IsTesting(tester)) {

        BeginTime(tester);
        testFunc.Func(buffer, color, start_x, start_y, end_x, end_y, width);
        EndTime(tester);
        CountBytes(tester, size);
      }
    }
  }

  return 0;
}
