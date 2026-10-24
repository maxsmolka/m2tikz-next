param(
    [Parameter(Mandatory=$true)][string]$CommandFile,
    [Parameter(Mandatory=$true)][string]$OutputFile,
    [Parameter(Mandatory=$true)][string]$ResultFile,
    [Parameter(Mandatory=$true)][double]$Seconds
)
$ErrorActionPreference = 'Stop'
$result = @{exitCode=-1; timedOut=$false; error=''}
try {
    # A suspended cmd process is assigned to a kill-on-close Job before it can
    # create children. Closing that Job also handles a launcher that exits
    # before its descendants. No global process-name matching or PID guessing.
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;
using System.Runtime.InteropServices;
using System.ComponentModel;
public static class M2TBoundedJob {
    [StructLayout(LayoutKind.Sequential)] struct IO { public ulong a,b,c,d,e,f; }
    [StructLayout(LayoutKind.Sequential)] struct BASIC {
        public long processTime, jobTime; public uint flags;
        public UIntPtr minWorking, maxWorking; public uint active;
        public UIntPtr affinity; public uint priority, scheduling;
    }
    [StructLayout(LayoutKind.Sequential)] struct EXTENDED {
        public BASIC basic; public IO io;
        public UIntPtr processMemory, jobMemory, peakProcess, peakJob;
    }
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] struct STARTUP {
        public uint size; public string reserved, desktop, title;
        public uint x,y,xSize,ySize,xCount,yCount,fill,flags;
        public ushort show, reservedSize; public IntPtr reservedPointer, stdin, stdout, stderr;
    }
    [StructLayout(LayoutKind.Sequential)] struct INFO {
        public IntPtr process, thread; public uint pid, tid;
    }
    [StructLayout(LayoutKind.Sequential)] struct ACCOUNTING {
        public long user, kernel, periodUser, periodKernel;
        public uint faults, total, active, terminated;
    }
    [DllImport("kernel32.dll", SetLastError=true)] static extern IntPtr CreateJobObject(IntPtr a, string n);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool SetInformationJobObject(IntPtr j, int c, ref EXTENDED v, uint s);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool AssignProcessToJobObject(IntPtr j, IntPtr p);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool TerminateJobObject(IntPtr j, uint c);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool TerminateProcess(IntPtr p, uint c);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool QueryInformationJobObject(
        IntPtr j, int c, out ACCOUNTING a, uint size, IntPtr returned);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool SetHandleInformation(IntPtr h, uint mask, uint flags);
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)] static extern bool CreateProcess(
        string app, StringBuilder cmd, IntPtr pa, IntPtr ta, bool inherit, uint flags,
        IntPtr env, string cwd, ref STARTUP startup, out INFO info);
    [DllImport("kernel32.dll", SetLastError=true)] static extern uint ResumeThread(IntPtr t);
    [DllImport("kernel32.dll", SetLastError=true)] static extern uint WaitForSingleObject(IntPtr h, uint ms);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool GetExitCodeProcess(IntPtr p, out uint c);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    static void Check(bool ok) { if (!ok) throw new Win32Exception(Marshal.GetLastWin32Error()); }
    public static int Run(string command, string output, double seconds, out bool timedOut) {
        timedOut=false;
        IntPtr job=IntPtr.Zero; INFO info=new INFO();
        using (FileStream stream=new FileStream(output, FileMode.Create, FileAccess.Write, FileShare.ReadWrite)) {
            try {
                job=CreateJobObject(IntPtr.Zero, null); Check(job!=IntPtr.Zero);
                EXTENDED limits=new EXTENDED(); limits.basic.flags=0x2000; // KILL_ON_JOB_CLOSE
                Check(SetInformationJobObject(job, 9, ref limits, (uint)Marshal.SizeOf(limits)));
                IntPtr handle=stream.SafeFileHandle.DangerousGetHandle();
                Check(SetHandleInformation(handle, 1, 1));
                STARTUP startup=new STARTUP(); startup.size=(uint)Marshal.SizeOf(startup);
                startup.flags=0x100; startup.stdout=handle; startup.stderr=handle;
                string shell=Environment.GetEnvironmentVariable("ComSpec");
                StringBuilder line=new StringBuilder("\""+shell+"\" /d /s /c \""+command+"\"");
                Check(CreateProcess(shell, line, IntPtr.Zero, IntPtr.Zero, true,
                    0x08000004, IntPtr.Zero, null, ref startup, out info)); // NO_WINDOW | SUSPENDED
                Check(AssignProcessToJobObject(job, info.process));
                Check(ResumeThread(info.thread)!=0xffffffff);
                uint wait=WaitForSingleObject(info.process, (uint)Math.Ceiling(seconds*1000));
                if (wait==258) {
                    timedOut=true;
                    Check(TerminateJobObject(job, 124));
                    Check(WaitForSingleObject(info.process, 5000)==0);
                    return 124;
                }
                Check(wait==0);
                uint exit; Check(GetExitCodeProcess(info.process, out exit));
                return unchecked((int)exit);
            } finally {
                // If assignment failed the suspended process must still die.
                try {
                    if (info.process!=IntPtr.Zero) TerminateProcess(info.process, 125);
                    if (job!=IntPtr.Zero) {
                        try {
                            Check(TerminateJobObject(job, 125));
                            var clock=System.Diagnostics.Stopwatch.StartNew();
                            ACCOUNTING accounting;
                            do {
                                Check(QueryInformationJobObject(job, 1, out accounting,
                                    (uint)Marshal.SizeOf(typeof(ACCOUNTING)), IntPtr.Zero));
                                if (accounting.active==0) break;
                                if (clock.ElapsedMilliseconds>5000)
                                    throw new InvalidOperationException("Job cleanup did not complete.");
                                System.Threading.Thread.Sleep(10);
                            } while (true);
                        } finally { CloseHandle(job); }
                    }
                } finally {
                    if (info.thread!=IntPtr.Zero) CloseHandle(info.thread);
                    if (info.process!=IntPtr.Zero) CloseHandle(info.process);
                }
            }
        }
    }
}
'@
    $expired = $false
    $command = [IO.File]::ReadAllText($CommandFile, [Text.Encoding]::UTF8)
    $result.exitCode = [M2TBoundedJob]::Run($command, $OutputFile, $Seconds, [ref]$expired)
    $result.timedOut = $expired
} catch {
    $result.error = $_.Exception.Message
}
[IO.File]::WriteAllText($ResultFile, ($result | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
