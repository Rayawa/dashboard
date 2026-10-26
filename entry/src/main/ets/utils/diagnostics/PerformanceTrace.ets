import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';

/** Named spans for DevEco Profiler; no per-frame console logging or growing in-memory samples. */
export class PerformanceTrace {
    private static sequence: number = 0;
    static begin(name: string): number {
        const id = ++PerformanceTrace.sequence;
        hiTraceMeter.startAsyncTrace(hiTraceMeter.HiTraceOutputLevel.COMMERCIAL, name, id, 'Dashboard');
        return id;
    }
    static finish(name: string, id: number): void {
        hiTraceMeter.finishAsyncTrace(hiTraceMeter.HiTraceOutputLevel.COMMERCIAL, name, id);
    }
    static measure<T>(name: string, action: () => T): T {
        hiTraceMeter.startSyncTrace(hiTraceMeter.HiTraceOutputLevel.COMMERCIAL, name);
        try { return action(); }
        finally { hiTraceMeter.finishSyncTrace(hiTraceMeter.HiTraceOutputLevel.COMMERCIAL); }
    }
}
