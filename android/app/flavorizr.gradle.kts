import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("app")

    productFlavors {
        create("dev") {
            dimension = "app"
            applicationId = "com.earth.amitabha.dev"
        }
        create("staging") {
            dimension = "app"
            applicationId = "com.earth.amitabha.staging"
        }
        create("prod") {
            dimension = "app"
            minSdk = 23
            applicationId = "com.earth.amitabha"
        }
        create("prodMeta") {
            dimension = "app"
            applicationId = "com.earth.amitabha"
            minSdk = 29
            targetSdk = 32    
        }   
    }
}