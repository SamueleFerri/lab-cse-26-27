package utils

import org.apache.spark.SparkContext
import org.apache.hadoop.fs.Path
import software.amazon.awssdk.auth.credentials.{AwsSessionCredentials, ProfileCredentialsProvider}
import software.amazon.awssdk.profiles.ProfileFile

import java.nio.file.Paths

object Commons {

  def initializeSparkContext(deploymentMode: String, sc: SparkContext): Unit = {
    if(deploymentMode == "remote" || deploymentMode == "sharedRemote"){
      val stream = Option(getClass.getResourceAsStream(Config.credentialsPath)).getOrElse {
        throw new IllegalStateException(
          s"AWS credentials resource not found: ${Config.credentialsPath}. " +
            "Create aws/credentials and rebuild the JAR before submitting a remote job.")
      }

      val provider = ProfileCredentialsProvider.builder()
        .profileFile(ProfileFile.builder().content(stream).`type`(ProfileFile.Type.CREDENTIALS).build())
        .profileName(sys.env.getOrElse("AWS_PROFILE", "default"))
        .build()

      try {
        val credentials = provider.resolveCredentials()
        val hadoopConf = sc.hadoopConfiguration
        hadoopConf.set("fs.s3a.fast.upload", "true")
        hadoopConf.set("fs.s3a.fast.upload.buffer", "bytebuffer")
        hadoopConf.set("fs.s3a.access.key", credentials.accessKeyId())
        hadoopConf.set("fs.s3a.secret.key", credentials.secretAccessKey())
        credentials match {
          case session: AwsSessionCredentials =>
            hadoopConf.set("fs.s3a.session.token", session.sessionToken())
            hadoopConf.set("fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.TemporaryAWSCredentialsProvider")
          case _ =>
            hadoopConf.unset("fs.s3a.session.token")
            hadoopConf.set("fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider")
        }
      } finally {
        provider.close()
      }
    }
  }

  def getDatasetPath(deploymentMode: String, localPath: String, remotePath: String): String = {
    if(deploymentMode == "local"){
      val absolutePath = Paths.get(localPath.stripPrefix("/")).toAbsolutePath.normalize()
      return new Path(absolutePath.toUri).toString
    }
    else if(deploymentMode == "sharedRemote"){
      return "s3a://" + Config.s3sharedBucketName + "/" + remotePath
    }
    else{
      return "s3a://" + Config.s3bucketName + "/" + remotePath
    }
  }

  def getDatasetPath(deploymentMode: String, path: String): String = {
    return getDatasetPath(deploymentMode, path, path)
  }

}
