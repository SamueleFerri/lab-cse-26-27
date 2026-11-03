package utils

object Config {

  // [CHANGE THIS] The name of your bucket on AWS S3
  val s3bucketName :String = "unibo-bd2627-egallinucci"

  // The name of the shared bucket on AWS S3 to read datasets (so you don't need to upload them in your bucket)
  val s3sharedBucketName :String = "unibo-bd2627-egallinucci-shared"
  // Classpath resource populated from the AWS CLI credentials file during the build.
  val credentialsPath :String = "/aws/credentials"

}
