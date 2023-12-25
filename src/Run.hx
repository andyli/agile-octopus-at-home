import sys.io.Process;
import sys.io.File;
import haxe.io.Path;
using DateTools;

class Run {
    static function cmd(command:String, args:Array<String>):Void {
        final process = new Process(command, args);
        final output = process.stdout.readAll().toString();
        final error = process.stderr.readAll().toString();
        final exitCode = process.exitCode();
        if (exitCode != 0) {
            throw '${command} failed with exit code ${exitCode}:\n${error}\n${output}';
        }
    }

    static function scheduleRunOnce(date:Date, name:String, ?args:Array<String>):Void {
        final scriptDir = Path.directory(Sys.programPath());
        final taskRunner = scriptDir + "\\task-runner.vbs";
        final taskRun = if (args == null || args.length == 0) {
            '${taskRunner}';
        } else {
            '${taskRunner} ${args.join(" ")}';
        }
        Schtasks.create(ONCE, name, taskRun, {
            startDate: date.format("%Y-%m-%d"),
            startTime: date.format("%H:%M"),
        });
    }

    static function main():Void {
        final scriptDir = Path.directory(Sys.programPath());
        Sys.setCwd(scriptDir);
        final logFile = Path.join(["logs", Date.now().format("%Y-%m-%d_%H-%M-%S") + ".log"]);
        switch (Sys.args()) {
            case []:
                File.saveContent(logFile, Sys.getCwd());
            case ["test"]:
                final now = Date.now();
                final schDate = now.delta(DateTools.minutes(1));
                final taskName = "test-run_" + schDate.format("%Y-%m-%d_%H-%M");
                scheduleRunOnce(schDate, taskName, ["test-run", taskName]);
            case ["test-run", taskName]:
                File.saveContent(logFile, "test-run");
                Schtasks.delete(taskName, {force: true});
            case ["start", taskName]:
                cmd("C:\\Program Files (x86)\\FAHClient\\HideConsole.exe", ['"C:\\Program Files (x86)\\FAHClient\\FAHClient.exe" --chdir C:\\ProgramData\\FAHClient']);
                cmd("C:\\Program Files (x86)\\FAHClient\\FAHClient.exe", ["--send-unpause"]);
                File.saveContent(logFile, "start");
                Schtasks.delete(taskName, {force: true});
            case ["stop", taskName]:
                cmd("C:\\Program Files (x86)\\FAHClient\\FAHClient.exe", ["--send-command", "shutdown"]);
                File.saveContent(logFile, "stop");
                Schtasks.delete(taskName, {force: true});
            case _:
                throw "unexpected args";
        }
    }
}
