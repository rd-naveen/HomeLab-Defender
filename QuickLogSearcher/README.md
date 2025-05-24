During one of My close friend's SecOps interview, He was tasked to analyze the 15Gb of log files, 
    the log file was presented with Ubuntu Desktop system GUI, (obiviously remoted)
    He tried differnt methods to parse the logs manually, using grep, and other linux commends, though he succeded in answering questions from the pannel about the logs. 

    I was curious to know, howe can acomplish this with quickly, without too much time wasting time on the parsing things. instead fous on the analysis part. 

        these are the conditions I'm focusing on now. 
            - No need to wait for too much time for the installtion to complete, either downloading big files or installing will causes too much time. 

            - It should support basic parsing, data converstions, and basic transformations. 
            
            - The system should be limited setup, 4-8gb of RAM and 2-4 core cpus,
                systems like Opensearch, logstash, kiban will need more of it, offcouse we could do with less, but i don't want to wait for paring and querying delays. 

            - The analysis data should not travel outside the org boundary: using cloud solutions like free Kusto clusters will need large network bandwidths and data is resided outside the boundary.

            - asume you were starting with clean ubuntu installation

        Here are the options I am aware for now. 
            -> Splunk local instance, we have docker image
            -> Kusto Emulator
                windows version of local env is very heavy, requires 10GB downloading
                but, linux version of local evn is very light, only requires 1gb of downloading, So let's go with that.
            -> graylog -> though it requires more steps for installation, but we have docker image for this
            -> wazuh -> docker image for this
            -> opensearch/opensearch dashboard/logstash etc. -> we have docker image for everything