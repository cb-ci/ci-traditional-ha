//Print Controller hostname to console, requires script approval!
def controllerHostName(){
    def hostname = InetAddress.getLocalHost().getHostName()
    echo "Jenkins Controller Hostname: ^${hostname}"
}
/**
 * Request was, if an pipeline using an SSH Agent gets reconnected to the next replica when the active replica fails
 */
pipeline {
    agent {
        /**
         * This label reference an SSH agent
         */
        label "ssh-agent"
    }
    /** trigger every minute
     triggers {
     cron '* * * * *'
     }*/
    stages {
        stage('Stage1') {
            steps {
                controllerHostName()
                //Print agent hostname to console and pause the build for X seconds
                sh '''
                    # set +x
                    # Get the current time in seconds since epoch
                    start_time=$(date +%s)
                    # Loop until 60 seconds have passed
                    while [ $(($(date +%s) - start_time)) -lt 60 ]; do
                        echo "Running... $(($(date +%s) - start_time)) seconds elapsed"
                        printf '%s %s\n' "$(date) Running on Agent-Pod: $(hostname)"
                        # sleep for X sec, kill the active replica now and check if SSH agent gets reconnected to the other replica
                        sleep 2
                    done    
                '''
                controllerHostName()
            }
        }
    }
}