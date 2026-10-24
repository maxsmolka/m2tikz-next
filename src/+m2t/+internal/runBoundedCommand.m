function result = runBoundedCommand(command, seconds)
%RUNBOUNDEDCOMMAND Supervise only the compiler's local process group/job.
%   Internal boundary, not a public export option. Never fall back to an
%   unbounded compiler when supervision is unavailable.
    if ~(isnumeric(seconds) && isscalar(seconds) && isreal(seconds) && ...
            isfinite(seconds) && seconds > 0 && seconds <= 86400)
        error('M2T:E001:InvalidArgument', 'Invalid internal process time budget.');
    end
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeFolder(folder));
    result = struct('exitCode', -1, 'output', '', 'timedOut', false, 'error', '');
    if ispc
        commandFile = fullfile(folder, 'command.txt');
        outputFile = fullfile(folder, 'output.txt');
        resultFile = fullfile(folder, 'result.json');
        m2t.internal.writeTextFile(commandFile, command);
        supervisor = fullfile(fileparts(mfilename('fullpath')), 'runBoundedWindows.ps1');
        powershell = fullfile(getenv('SystemRoot'), 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe');
        invocation = [quoteWindows(powershell) ' -NoProfile -NonInteractive -File ' ...
            quoteWindows(supervisor) ' -CommandFile ' quoteWindows(commandFile) ...
            ' -OutputFile ' quoteWindows(outputFile) ' -ResultFile ' quoteWindows(resultFile) ...
            ' -Seconds ' sprintf('%.6f', seconds) ' 2>&1'];
        [status, text] = system(invocation);
        if status ~= 0 || exist(resultFile, 'file') ~= 2
            result.error = ['Windows process supervisor unavailable. ' text];
        else
            data = jsondecode(fileread(resultFile));
            result.exitCode = data.exitCode;
            result.timedOut = data.timedOut;
            result.error = data.error;
            if exist(outputFile, 'file') == 2, result.output = fileread(outputFile); end
        end
    else
        [status, executable] = system('command -v python3');
        if status ~= 0 || isempty(strtrim(executable))
            result.error = 'Python 3 is required for supervised compilation on POSIX.';
            return;
        end
        executable = strtrim(executable);
        commandFile = fullfile(folder, 'command.txt');
        outputFile = fullfile(folder, 'output.txt');
        resultFile = fullfile(folder, 'result.json');
        m2t.internal.writeTextFile(commandFile, command);
        supervisor = fullfile(fileparts(mfilename('fullpath')), 'runBoundedPosix.py');
        invocation = [quotePosix(executable) ' ' quotePosix(supervisor) ' ' ...
            quotePosix(commandFile) ' ' quotePosix(outputFile) ' ' quotePosix(resultFile) ...
            ' ' sprintf('%.6f', seconds) ' 2>&1'];
        [status, text] = system(invocation);
        if status ~= 0 || exist(resultFile, 'file') ~= 2
            result.error = ['POSIX process supervisor unavailable. ' text];
        else
            data = jsondecode(fileread(resultFile));
            result.exitCode = data.exitCode;
            result.timedOut = data.timedOut;
            result.error = data.error;
            if exist(outputFile, 'file') == 2, result.output = fileread(outputFile); end
        end
    end
    clear cleanup;
end

function value = quotePosix(value)
    sq = char(39);
    value = [sq strrep(value, sq, [sq '"' sq '"' sq]) sq];
end

function value = quoteWindows(value)
    if any(ismember(value, [char(0:31) '"%!']))
        error('M2T:C005:UnsafeProcessArgument', 'Unsafe supervisor path.');
    end
    value = ['"' value '"'];
end

function removeFolder(folder)
    if exist(folder, 'dir') == 7, rmdir(folder, 's'); end
end
