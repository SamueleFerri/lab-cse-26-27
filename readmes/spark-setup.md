# Spark setup

This readme provides installation instructions to replicate the configuration of lab machines.
These instructions are meant for **Windows**;
if you use a different OS, they may be invalid/incomplete.

### Requirements

- **Java 17 (any), 21 (any), or 25 (25.0.3 or upper)** - needed by Spark 4.
- For the notebook environment, either:
  - **Python 3** and **Visual Studio Code**
    - If you want to run Scala code in the notebook environment, 
      you need the spylon-kernel package, but it is not recommended
  - **Docker Desktop**

### AWS CLI

- Download it from [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and install it.

### Apache Spark

- Download it from [here](https://www.apache.org/dyn/closer.lua/spark/spark-4.2.0/spark-4.2.0-bin-hadoop3.tgz).
- Unzip and put it in c:/ (or any other location; in the following, I will assume it is unzipped in c:/)
- Add the following environment variables (assuming JAVA_HOME already exists)
  - HADOOP_HOME = c:/spark-4.2.0-bin-hadoop3
  - SPARK_HOME = c:/spark-4.2.0-bin-hadoop3
  - PATH = PATH + c:/spark-4.2.0-bin-hadoop3/bin
- In Spark's folder, add an empty ```history``` folder, then edit the file **conf/spark-default.conf** to add the following parameters
  ```
  spark.eventLog.enabled           true
  spark.history.fs.logDirectory    file:///c:/spark-4.2.0-bin-hadoop3/history/
  spark.eventLog.dir               file:///c:/spark-4.2.0-bin-hadoop3/history/
  ```
- Download the following files and put them in the **bin** folder inside Spark's folder
  - [Winutils.exe](https://github.com/kontext-tech/winutils/raw/refs/heads/master/hadoop-3.4.0-win10-x64/bin/winutils.exe)
	- [hadoop.dll](https://github.com/kontext-tech/winutils/raw/refs/heads/master/hadoop-3.4.0-win10-x64/bin/hadoop.dll) (warning: your browser may block this download)

### Visual Studio Code extensions

- AWS Toolkit
  - Needed to access, navigate, and upload files to S3, as well as to see running EC2 instances
- Amazon EMR Toolkit 
  - Needed to see running EMR clusters

### Notebooks for Apache Spark

#### Using plain installation

To run local notebooks, you need a local Python installation with the following requirements.

```
pip install findspark
pip install jupyter
```

##### (Optional) If you want to run Scala code in notebooks

The `spylon-kernel` is the kernel used to run Scala code within Jupyter. 

```
pip install spylon-kernel
python -m spylon_kernel install
```

However, its configuration is often problematic and ultimately **discouraged**. It is much easier to run Python code (PySpark) using a Python kernel.

##### (Optional) If you want to use IntelliJ

To enable notebooks in IntelliJ, you must perform the following operations.
- Go to File > Project structure > SDKs; here, add a new SDK pointing to the "python.exe" file on your computer.
  - In the Packages tab of the added SDK, make sure that jupyter and findspark are installed (if they are not, install them; **this may take a while**).
  - If you want to run Scala code, make sure that python-kernel is also installed.

<!-- - Go to File > Settings > Languages & Frameworks > Jupyter > Jupyter Servers; here, select the ".main" of your project and select the configured Python SDK under "Python intepreter". -->

Now, you can open the notebook and start running the cells. *Make sure that the proper kernel is chosen!*



#### Using Docker

- Launch Docker Desktop
- Download the Docker image with Spark 3.5.0 ([reference](https://hub.docker.com/r/jupyter/all-spark-notebook))
    ```bash
    docker pull jupyter/all-spark-notebook:spark-3.5.0
    ```
- Open the **PowerShell** in the project main directory (lab-cse-25-26)
  - Launch the Docker image
    ```bash
    docker run -d `
      -p 8888:8888 `
      -p 4040:4040 `
      -p 18080:18080 `
      -v "${PWD}:/home/jovyan/work" `
      jupyter/all-spark-notebook:spark-3.5.0
    ```
- Open Docker Desktop > Open the running container > Access the Jupyter notebook by clicking on the link that looks like
  `http://127.0.0.1:8888/lab?token=12345etc`

Note: The Jupyter notebook can be accessed via IntelliJ IDEA as well, 
but autocompletion doesn't work very well. You can also use Visual Studio Code.



### Local History Server

You can use the History Server to check the execution plans of previously executed jobs.
**It doesn't matter where the job was executed**: you can download the history of a Spark
job from AWS, put it in the "history" folder within Spark's installation folder, and
check it out locally.

To launch it, open a Git Bash on Spark's folder and launch this command. 

```
bin/spark-class.cmd org.apache.spark.deploy.history.HistoryServer
```

The History Server will show up at [http://localhost:18080](http://localhost:18080).