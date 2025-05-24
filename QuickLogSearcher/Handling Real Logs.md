
Source logs
    https://csr.lanl.gov/data/
    https://github.com/sbousseaden/EVTX-ATTACK-SAMPLES/tree/master
    https://docs.fortinet.com/document/fortigate/6.2.9/cookbook/986892/sample-logs-by-log-type



    Send Windows Etw logs to Kusto (Get-WinEvent -LogName "Security" -MaxEvents 100 | ConvertTo-Json > windows-security-event.json) 
    - get sample events from the windows security events
        Get-WinEvent -LogName "Security" -MaxEvents 100 | ConvertTo-Json > windows-events-samples.json

        kusto requires the JSONL  format not the Json array, so need to covert this using https://codebeautify.org/json-to-jsonl-converter#

        but for larger files, we need a alternative

    - move the logs to the kusto emulator mapped location
        copy .\windows-events-samples.json D:\host\local\


    - We can use the eric Zimmerman tools EvtxECmd.exe to covert the logs into json format, (it looks like in the JSONL, validated using https://jsonlines.org/validator/)

        now we need to inject the logs to Kusto env, The ideas here is that, we will map the know fields(which are common across all logs types, into the table and for the other fields we will preserve the raw data in the separate col. so if required we can create new colums when needed)
        
        .ingest into table WindowsRaw(@"/kustodata/20250524075444_EvtxECmd_Output.json") with (
                format='json', 
                ingestionMapping =
                ```
                        [ 
                        {"column":"TimeCreated","Properties":{"path":"$.TimeCreated"}},
                        {"column":"EventId","Properties":{"path":"$.EventId"}},
                        {"column":"raw","Properties":{"path":"$"}},
                        ]
                        ```)


    Send Sysmon logs to kusto
    Firewall logs
    Zeek Logs -> (download some sample malware traffics and convert them to zeek logs)

    Mitre Attack Mapping
        on the logs,  

    How to send the logs to remote in a batch
        -> when storing the logs put them into a smaller files of 100 events or something, 
            the file format should reflect the datetime of it's creation
        -> check if the file is locked
            if yes, then ignore that file and send the un-locked files and remove the unlocked files
