export class Logger {
    private static prefix: string = '[Dashboard]';

    private static format(level: string, args: string[]): string {
        const scope = args.length > 1 ? args[0] : 'App';
        const message = args.length > 1 ? args.slice(1).join(' ') : (args[0] ?? '');
        return `${Logger.prefix}[${scope}][${level}] ${message}`;
    }

    static debug(...args: string[]): void {
        console.info(Logger.format('DEBUG', args));
    }

    static info(...args: string[]): void {
        console.info(Logger.format('INFO', args));
    }

    static warn(...args: string[]): void {
        console.warn(Logger.format('WARN', args));
    }

    static error(...args: string[]): void {
        console.error(Logger.format('ERROR', args));
    }
}
