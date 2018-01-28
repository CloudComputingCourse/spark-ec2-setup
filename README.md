`spark-ec2-setup` allows you to launch, manage and shut down Apache Spark clusters on Amazon EC2.
Currently it only supports Spark v2.1.0 along with HDFS v2.7.3 and must use AMI ami-6d15ec7b (or images
created based on it). This tool is based on `spark-ec2` (https://github.com/amplab/spark-ec2) from AMP Lab.
Please make sure you use Python 2.7 with this tool.

## Before You Start

-   Create an Amazon EC2 key pair for yourself. This can be done by
    logging into your Amazon Web Services account through the [AWS
    console](http://aws.amazon.com/console/), clicking Key Pairs on the
    left sidebar, and creating and downloading a key. Make sure that you
    set the permissions for the private key file to `600` (i.e. only you
    can read and write it) so that `ssh` will work.
-   Whenever you want to use the `spark-ec2` script, set the environment
    variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to your
    Amazon EC2 access key ID and secret access key. These can be
    obtained from the [AWS homepage](http://aws.amazon.com/) by clicking
    Account > Security Credentials > Access Credentials.

## Launching a Cluster

-   Go into the `ec2` directory in the release of Apache Spark you downloaded.
-   Example:
    `./spark-ec2 -k <keypair> -i <key-file> -s <num-slaves> -t <instance-type> -a <AMI-ID>
    -v <spark-version> --ebs-vol-size=<size-in-GB> --ebs-vol-type=<ebs-vol-type> 
    --ebs-vol-num=<1-to-8> --spot-price=<spot-price> launch <cluster-name>`,
    where `<keypair>` is the name of your EC2 key pair (that you gave it
    when you created it), `<key-file>` is the private key file for your
    key pair, `<num-slaves>` is the number of slave nodes to launch (try
    1 at first), `<instance-type>` is the instance type (e.g. m4.xlarge)
    and `<cluster-name>` is the name to give to your
    cluster. If `--spot-price` is set, the cluster is launched as spot instances 
    with the given maximum price.
 -  EBS volume:
    The script requires you to add at least one EBS volume besides the root volume. The first EBS volume added
    will be mounted and used for HDFS. You can add more than one volumes, but they will not be mounted by `spark-ec2`.
 -  Python version: Please make sure the default "python" command points to Python 2.7. You can check this with
    `python --version`. Alternatively, you can change the shell script file `spark-ec2` and point the python command to
	Python 2.7.
    
## Other Actions

 - You may also `stop` a running cluster and `start` the stopped cluster. When a stopped cluster is restarted, it preserves
   the data stored in HDFS. Spot instances do not support start and stop.
 - You can also `destroy` a cluster, which terminates the instances and delete the EBS volume.
