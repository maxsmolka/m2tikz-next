function summary = runCompilerTimeoutTests(out)
%RUNCOMPILERTIMEOUTTESTS Real hung discovery/compiler processes, no TeX needed.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root, 'src'));
    if nargin < 1, out = fullfile(root, '.audit', 'compiler-timeout'); end
    if exist(out, 'dir') ~= 7, mkdir(out); end
    out = tempname(out); mkdir(out);
    before = {getenv('TEXMFVAR'), getenv('TEXMFCACHE'), getenv('TEXINPUTS')};
    tex = fullfile(out, 'fixture.tex'); pdf = fullfile(out, 'fixture.pdf');
    marker = fullfile(out, 'child-escaped.txt'); record = fullfile(out, 'staging.txt');
    m2t.internal.writeTextFile(tex, 'Synthetic process test, not TeX.');
    if ispc
        compiler = fullfile(out, 'fake-compiler.cmd');
        hang = 'ping -n 30 127.0.0.1 >nul';
        child = ['start "" /b powershell.exe -NoProfile -NonInteractive -Command "Start-Sleep -Seconds 4; ' ...
            '[IO.File]::WriteAllText(''' marker ''',''escaped'')"'];
        body = sprintf(['@echo off\r\nsetlocal EnableDelayedExpansion\r\n' ...
            'if "%%~1"=="--version" (echo Fake compiler&exit /b 0)\r\n' ...
            'for %%%%A in (%%*) do (\r\nset "arg=%%%%~A"\r\n' ...
            'if "!arg:~0,18!"=="-output-directory=" set "staging=!arg:~18!"\r\n)\r\n' ...
            'echo !staging!>"%s"\r\necho partial>"!staging!\fixture.pdf"\r\n%s\r\n%s\r\n'], ...
            record, child, hang);
        discovery = fullfile(out, 'hung-discovery.cmd');
        m2t.internal.writeTextFile(discovery, sprintf('@echo off\r\n%s\r\n', hang));
    else
        compiler = fullfile(out, 'fake-compiler.sh');
        body = sprintf(['#!/bin/sh\nif [ "$1" = "--version" ]; then echo Fake; exit 0; fi\n' ...
            'for arg do case "$arg" in -output-directory=*) staging=${arg#-output-directory=};; esac; done\n' ...
            'printf "%%s" "$staging" > "%s"\nprintf partial > "$staging/fixture.pdf"\n' ...
            '(sleep 4; echo escaped > "%s") &\nsleep 30\n'], record, marker);
        discovery = fullfile(out, 'hung-discovery.sh');
        m2t.internal.writeTextFile(discovery, sprintf('#!/bin/sh\nsleep 30\n'));
    end
    m2t.internal.writeTextFile(compiler, body);
    if ~ispc
        assert(system(['chmod +x "' compiler '" "' discovery '"']) == 0);
    end
    started = tic;
    result = m2t.internal.compileLuaLatex(tex, pdf, compiler, 1);
    assert(toc(started) < 25, 'Compiler deadline did not return promptly.');
    timeoutResult(result, pdf);
    assert(exist(record, 'file') == 2, 'Fake compiler never reached staging.');
    assert(exist(strtrim(fileread(record)), 'dir') ~= 7, 'Staging was not cleaned.');
    after = {getenv('TEXMFVAR'), getenv('TEXMFCACHE'), getenv('TEXINPUTS')};
    assert(isequal(before, after), 'Compiler environment was not restored.');
    result = m2t.internal.compileLuaLatex(tex, pdf, discovery, 1);
    timeoutResult(result, pdf);
    for code = [0 124 137]
        if ispc, command = sprintf('exit /b %d', code);
        else, command = sprintf('exit %d', code); end
        value = m2t.internal.runBoundedCommand(command, 2);
        assert(isempty(value.error) && ~value.timedOut && value.exitCode == code);
    end
    if ispc
        loud = 'for /L %i in (1,1,3000) do @echo output-buffer-check';
    else
        loud = 'i=0; while [ "$i" -lt 3000 ]; do echo output-buffer-check; i=$((i+1)); done';
    end
    value = m2t.internal.runBoundedCommand(loud, 10);
    assert(isempty(value.error) && ~value.timedOut && value.exitCode == 0);
    assert(numel(value.output) > 32768, 'Large output was blocked or lost.');
    normalMarker = fullfile(out, 'early-exit-child.txt');
    if ispc
        earlyExit = ['start "" /b powershell.exe -NoProfile -NonInteractive -Command "Start-Sleep -Seconds 4; ' ...
            '[IO.File]::WriteAllText(''' normalMarker ''',''escaped'')" & exit /b 0'];
    else
        earlyExit = ['(sleep 4; echo escaped > "' normalMarker '") & exit 0'];
    end
    value = m2t.internal.runBoundedCommand(earlyExit, 2);
    assert(isempty(value.error) && ~value.timedOut && value.exitCode == 0);
    if ~ispc
        oldPath = getenv('PATH');
        restorePath = onCleanup(@() setenv('PATH', oldPath));
        setenv('PATH', fullfile(out, 'missing-tools'));
        unavailable = m2t.internal.compileLuaLatex(tex, pdf, compiler, 1);
        assert(~unavailable.success);
        assert(strcmp(unavailable.diagnostics(1).code, 'M2T:C007:ProcessSupervisorFailed'));
        clear restorePath;
    end
    % A child that inherited the group/job must not survive its parent timeout.
    pause(4.5);
    assert(exist(marker, 'file') ~= 2, 'Timed-out compiler child survived.');
    assert(exist(normalMarker, 'file') ~= 2, 'Child survived an early launcher exit.');
    summary = struct('failures', 0, 'nativeWindows', ispc, 'outputDirectory', out);
    fprintf('COMPILER_TIMEOUT_PASS: discovery/build/children/cleanup/environment/exit-codes/large-output\n');
end

function timeoutResult(result, pdf)
    assert(~result.success && exist(pdf, 'file') ~= 2);
    assert(strcmp(result.diagnostics(1).code, 'M2T:C006:CompilerTimeout'));
    assert(strcmp(result.diagnostics(1).stage, 'compile'));
    assert(exist(result.logPath, 'file') == 2);
    assert(~isempty(strfind(fileread(result.logPath), 'time limit'))); %#ok<STREMP>
end
