allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 1. CHÈN ĐOẠN CODE SỬA LỖI NAMESPACE NGAY SAU ALLPROJECTS
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                if (getNamespace.invoke(androidExt) == null) {
                    val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(androidExt, project.group.toString())
                }
            } catch (e: Exception) {
                // Bỏ qua nếu extension không hỗ trợ namespace
            }
        }
    }
}

// 2. CÁC CẤU HÌNH GỐC CỦA FLUTTER ĐƯỢC GIỮ NGUYÊN BÊN DƯỚI
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}