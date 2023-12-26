import js.lib.Date as JsDate;
import sys.io.Process;
import sys.io.File;
import haxe.io.Path;
using DateTools;

enum TaskType {
    TStart;
    TStop;
}

class Run {
    static function cmd(command:String, args:Array<String>):Void {
        final exitCode = Sys.command(command, args);
        if (exitCode != 0) {
            throw '${command} failed with exit code ${exitCode}';
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

    static function start():Void {
        cmd("C:\\Program Files (x86)\\FAHClient\\HideConsole.exe", ["C:\\Program Files (x86)\\FAHClient\\FAHClient.exe", "--chdir", "C:\\ProgramData\\FAHClient"]);
        cmd("C:\\Program Files (x86)\\FAHClient\\FAHClient.exe", ["--send-unpause"]);
    }

    static function stop():Void {
        cmd("C:\\Program Files (x86)\\FAHClient\\FAHClient.exe", ["--send-command", "shutdown"]);
    }

    static function main():Void {
        final scriptDir = Path.directory(Sys.programPath());
        Sys.setCwd(scriptDir);
        js.Lib.require('dotenv').config();
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
            case ["start"]:
                start();
                File.saveContent(logFile, "start");
            case ["start", taskName]:
                start();
                File.saveContent(logFile, "start " + taskName);
                Schtasks.delete(taskName, {force: true});
            case ["stop"]:
                stop();
                File.saveContent(logFile, "stop");
            case ["stop", taskName]:
                stop();
                File.saveContent(logFile, "stop" + taskName);
                Schtasks.delete(taskName, {force: true});
            case ["getProducts"]:
                new OctopusEnergyApi(Sys.getEnv("OCTOPUS_ENERGY_API_KEY"))
                    .getProducts()
                    .then(o -> trace(o));
            case ["getElectricityStandardUnitRates"]:
                new OctopusEnergyApi(Sys.getEnv("OCTOPUS_ENERGY_API_KEY"))
                    .getElectricityStandardUnitRates(
                        Sys.getEnv("OCTOPUS_ENERGY_PRODUCT_CODE"),
                        Sys.getEnv("OCTOPUS_ENERGY_TARIFF_CODE"),
                        {
                            periodFrom: Date.now(),
                            periodTo: Date.now().delta(DateTools.hours(1)),
                        }
                    )
                    .then(o -> trace(o));
            case ["schedule-next-day"]:
                final now = Date.now();
                new OctopusEnergyApi(Sys.getEnv("OCTOPUS_ENERGY_API_KEY"))
                    .getElectricityStandardUnitRates(
                        Sys.getEnv("OCTOPUS_ENERGY_PRODUCT_CODE"),
                        Sys.getEnv("OCTOPUS_ENERGY_TARIFF_CODE"),
                        {
                            periodFrom: now,
                            periodTo: now.delta(DateTools.days(1)),
                        }
                    )
                    .then(o -> {
                        final rates = o.results
                            .map(r -> {
                                from: JsDate.toHaxeDate(new JsDate(r.valid_from)),
                                to: JsDate.toHaxeDate(new JsDate(r.valid_to)),
                                rate: r.value_inc_vat,
                            })
                            .filter(r -> r.from.getTime() > now.getTime());
                        rates.sort((a, b) -> a.from.getTime() - b.from.getTime() > 0 ? 1 : -1);
                        // trace(rates);
                        rates;
                    })
                    .then(rates -> {
                        final tasks:Array<{ type:TaskType, at:Date }> = [];
                        for (r in rates) {
                            switch (tasks[tasks.length-1]) {
                                case null | { type: TStop, at: _ }:
                                    if (r.rate < 0) {
                                        tasks.push({ type: TStart, at: r.from });
                                    }
                                case { type: TStart, at: _ }:
                                    if (r.rate > 0) {
                                        tasks.push({ type: TStop, at: r.from });
                                    }
                            }
                        }
                        // trace(tasks);
                        tasks;
                    })
                    .then(tasks -> {
                        for (t in tasks) {
                            switch (t.type) {
                                case TStart:
                                    final taskName = "agile-octopus-at-home_" + t.at.format("%Y-%m-%d_%H-%M") + "_start";
                                    scheduleRunOnce(t.at, taskName, ["start", taskName]);
                                case TStop:
                                    final taskName = "agile-octopus-at-home_" + t.at.format("%Y-%m-%d_%H-%M") + "_stop";
                                    scheduleRunOnce(t.at, taskName, ["stop", taskName]);
                            }
                        }
                    });
            case _:
                throw "unexpected args";
        }
    }
}
