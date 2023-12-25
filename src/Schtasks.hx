enum abstract ScheduleType(String) to String {
    final MINUTE; // Specifies the number of minutes before the task should run.
    final HOURLY; // Specifies the number of hours before the task should run.
    final DAILY; // Specifies the number of days before the task should run.
    final WEEKLY; // Specifies the number of weeks before the task should run.
    final MONTHLY; // Specifies the number of months before the task should run.
    final ONCE; // Specifies that that task runs once at a specified date and time.
    final ONSTART; // Specifies that the task runs every time the system starts. You can specify a start date, or run the task the next time the system starts.
    final ONLOGON; // Specifies that the task runs whenever a user (any user) logs on. You can specify a date, or run the task the next time the user logs on.
    final ONIDLE; // Specifies that the task runs whenever the system is idle for a specified period of time. You can specify a date, or run the task the next time the system is idle.
    final ONEVENT; // Specifies that the task runs based on an event that matches information from the system event log including the EventID.
}

enum abstract ScheduleLevel(String) to String {
    final LIMITED; // scheduled tasks will be ran with the least level of privileges, such as Standard User accounts
    final HIGHEST; // scheduled tasks will be ran with the highest level of privileges, such as Superuser accounts
}

typedef SchtasksCreateOptions = {
    /**
     * Specifies the date on which the task schedule starts. The default value is the current date on the local computer. The format for Startdate varies with the locale selected for the local computer in Regional and Language Options. Only one format is valid for each locale. The valid date formats include (be sure to choose the format most similar to the format selected for Short date in Regional and Language Options on the local computer).
     */
    final ?startDate:String;

    /**
     * Specifies the start time for the task, using the 24-hour time format, HH:mm. The default value is the current time on the local computer. The /st parameter is valid with MINUTE, HOURLY, DAILY, WEEKLY, MONTHLY, and ONCE schedules. It's required for a ONCE schedule.
     */
    final ?startTime:String;

    /**
     * Specifies how many minutes the computer is idle before the task starts. A valid value is a whole number from 1 to 999. This parameter is valid only with an ONIDLE schedule, and then it's required.
     */
    final ?idleTime:Int;

    /**
     * Specifies how often the task runs within its schedule type.
     */
    final ?modifiers:String;

    /**
     * Specifies the Run Level for the job. Acceptable values are LIMITED (scheduled tasks will be ran with the least level of privileges, such as Standard User accounts) and HIGHEST (scheduled tasks will be ran with the highest level of privileges, such as Superuser accounts). The default value is Limited.
     */
    final ?level:ScheduleLevel;

    /**
     * Specifies the name or IP address of a remote computer (with or without backslashes). The default is the local computer.
     */
    final ?computer:String;

    /**
     * Creates a task specified in the XML file. Can be combined with the /ru and /rp parameters, or with the /rp parameter by itself if the XML file already contains the user account information.
     */
    final ?xmlfile:String;

    /**
     * Specifies to delete the task upon the completion of its schedule.
     */
    final ?deleteUponCompletion:Bool;
}

typedef SchtasksDeleteOptions = {
    /**
     * Suppresses the confirmation message. The task is deleted without warning.
     */
    final ?force:Bool;
}

class Schtasks {
    /**
     * https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/schtasks-create
     */
    static public function create(scheduletype:ScheduleType, taskname:String, taskrun:String, ?opts:SchtasksCreateOptions):Void {
        final args = [
            "/create",
            "/sc", scheduletype,
            "/tn", taskname,
            "/tr", taskrun,
        ];
        if (opts != null) {
            if (opts.startDate != null) {
                args.push("/sd");
                args.push(opts.startDate);
            }
            if (opts.startTime != null) {
                args.push("/st");
                args.push(opts.startTime);
            }
            if (opts.idleTime != null) {
                args.push("/i");
                args.push(Std.string(opts.idleTime));
            }
            if (opts.modifiers != null) {
                args.push("/mo");
                args.push(opts.modifiers);
            }
            if (opts.level != null) {
                args.push("/rl");
                args.push(opts.level);
            }
            if (opts.computer != null) {
                args.push("/s");
                args.push(opts.computer);
            }
            if (opts.xmlfile != null) {
                args.push("/xml");
                args.push(opts.xmlfile);
            }
            if (opts.deleteUponCompletion != null) {
                args.push("/z");
            }
        }
        Sys.command("schtasks", args);
    }

    static public function delete(taskname:String, ?opts:SchtasksDeleteOptions):Void {
        final args = [
            "/delete",
            "/tn", taskname,
        ];
        if (opts != null) {
            if (opts.force != null) {
                args.push("/f");
            }
        }
        Sys.command("schtasks", args);
    }
}