#ifndef REPETITION_TESTER
#define REPETITION_TESTER

typedef float f32;
typedef double f64;
typedef int i32;
typedef long i64;
typedef unsigned int u32;
typedef unsigned long u64;
struct Profiler {
  u64 StartTSC;
  u64 EndTSC;
};
typedef struct Profiler Profiler;

extern Profiler profiler;
u64 ReadCPUTimer(void);
u64 EstimateCPUTimerFreq(void);

void initProfiler();
void displayProfilingResult();
#define ABS(x)                ((x) < 0 ? -(x) : x)

#define PROFILER 1
#if PROFILER

struct ProfileAnchor {
  u64 elapsedExclusive;
  u64 elapsedInclusive;
  u64 hitCount;
  u64 processedByteCount;
  char const *label;
};
typedef struct ProfileAnchor ProfileAnchor;

extern ProfileAnchor globalProfileAnchors[4096];
extern u32 globalProfilerParentIndex;

struct ProfileBlock {
  char const *label;
  u64 oldElapsedInclusive;
  u64 startTime;
  u32 parentIndex;
  u32 index;
};
typedef struct ProfileBlock ProfileBlock;
void initProfileBlock(ProfileBlock *block, char const *label_, u32 index_,
                      u64 byteCount);
void exitProfileBlock(ProfileBlock *block);

#define NameConcat2(A, B) A##B
#define NameConcat(A, B) NameConcat2(A, B)
#define TimeBandwidth(Name, ByteCount)                                         \
  ProfileBlock Name;                                                           \
  initProfileBlock(&Name, "Name", __COUNTER__ + 1, ByteCount);
#define ExitBlock(Name) exitProfileBlock(&Name)
#define TimeBlock(Name) TimeBandwidth(Name, 0)
#define ProfilerEndOfCompilationUnit                                           \
  static_assert(                                                               \
      __COUNTER__ < ArrayCount(GlobalProfilerAnchors),                         \
      "Number of profile points exceeds size of profiler::Anchors array")
#define TimeFunction TimeBlock(__func__)

#else

#define TimeBlock(blockName)
#define TimeFunction
#endif
#include "string.h"
enum TestMode {
  TestMode_Uninitialized,
  TestMode_Testing,
  TestMode_Completed,
  TestMode_Error
};
typedef enum TestMode TestMode;
struct RepetitionTestResults {
  u64 testCount;
  u64 totalTime;
  u64 maxTime;
  u64 minTime;
  u64 worstTest;
};
typedef struct RepetitionTestResults RepetitionTestResults;

struct RepetitionTester {
  u64 targetProcessedByteCount;
  u64 CPUTimerFreq;
  u64 tryForTime;
  u64 testsStartedAt;

  TestMode mode;
  bool printNewMinimums;
  u32 openBlockCount;
  u32 closeBlockCount;
  u64 timeAccumulatedOnThisTest;
  u64 bytesAccumulatedOnThisTest;

  RepetitionTestResults results;
};
typedef struct RepetitionTester RepetitionTester;
int runTester();

#endif
