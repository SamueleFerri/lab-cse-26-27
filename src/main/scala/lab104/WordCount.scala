package lab104

import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import utils._

object WordCount {

  val inputFile = "/datasets/divinacommedia.txt"
  val outputDir = "/output/myFirstWordCount" // The output directory should NOT exist

  def main(args: Array[String]): Unit = {

    if(args.length == 0){
      throw new IllegalArgumentException(
        "Missing deployment mode. Expected local, remote or sharedRemote as the first application argument.")
    }
    val deploymentMode = args(0)
    if (deploymentMode != "local" && deploymentMode != "remote" && deploymentMode != "sharedRemote") {
      throw new IllegalArgumentException(
        s"Invalid deployment mode '$deploymentMode'. Expected local, remote or sharedRemote.")
    }

    // Create a SparkConf object; the configuration settings you put here will override those given in the spark-submit
    val sparkConf = new SparkConf()
      .setAppName("Word Count")
      .setMaster(if (deploymentMode == "local") "local[4]" else "yarn")
    val sc = new SparkContext(sparkConf)
    Commons.initializeSparkContext(deploymentMode, sc)
    val writeMode = if (deploymentMode == "sharedRemote") "remote" else deploymentMode

    val myRdd = sc.textFile(Commons.getDatasetPath(deploymentMode, inputFile),4)
    myRdd.
      flatMap(_.split(" ") ).
      map(x => (x,1)).
      reduceByKey(_+_).
      map({case (k,v) => (v,k)}).
      sortByKey(false).
      coalesce(1).
      saveAsTextFile(Commons.getDatasetPath(writeMode,outputDir))
  }

}
