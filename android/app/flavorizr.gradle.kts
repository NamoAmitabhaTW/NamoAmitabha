import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("app")

    productFlavors {
        create("dev") {
            dimension = "app"
            applicationId = "com.earth.amitabha.dev"
            resValue(type = "string", name = "app_name", value = "念佛app Dev")
        }
        create("staging") {
            dimension = "app"
            applicationId = "com.earth.amitabha.staging"
            resValue(type = "string", name = "app_name", value = "念佛app Staging")
        }
        create("prod") {
            dimension = "app"
            applicationId = "com.earth.amitabha"
            resValue(type = "string", name = "app_name", value = "念佛app")
        }
    }
}