echo "#########################################################"
echo "1.   INSTALL PREREQUIREMENTS"
echo "#########################################################"
read -p "Install bazel? (choose No if already installed) [Yes/No]" answer
case "$answer" in
    Yes|yes|Y|y|"")
        echo "install bazel and dependancys..."
        sudo add-apt-repository ppa:webupd8team/java
        sudo apt-get update
        sudo apt-get install oracle-java8-installer
	sudo apt install curl
	sudo apt install git
        echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
        curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -
        sudo apt-get update && sudo apt-get install bazel
        sudo apt-get upgrade bazel
        ;;

    No|no|N|n) 
        echo "Continue without installing bazel"
        ;;
        
        *) echo "Unbekannter Parameter" 
        ;;

esac


echo "#########################################################"
echo "2.   GET TENSORFLOW"
echo "#########################################################"
sudo apt-get install git
git clone https://github.com/tensorflow/tensorflow.git


echo "#########################################################"
echo "3.   BUILD AND RUN RETRAINER"
echo "#########################################################"
cd tensorflow
bazel build tensorflow/examples/image_retraining:retrain
bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
bazel-bin/tensorflow/examples/image_retraining/retrain --image_dir ../data
# tensorboard --logdir /tmp/retrain_logs
# localhost:6006


echo "#########################################################"
echo "4.   GET ANDROID SDK AND NDK"
echo "#########################################################"

# get sdk
wget https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz
tar xvzf android-sdk_r24.4.1-linux.tgz -C

# get ndk
wget https://dl.google.com/android/repository/android-ndk-r12b-linux-x86_64.zip
unzip android-ndk-r12b-linux-x86_64.zip -d


echo "#########################################################"
echo "5.   MODIFY WORKSPACE"
echo "#########################################################"

sed -ie 's/#android_sdk_repository(/android_sdk_repository(/g' WORKSPACE
sed -ie 's/#    name = "androidsdk",/    name = "androidsdk",/g' WORKSPACE
sed -ie 's/#    api_level = 23,/    api_level = 23,/g' WORKSPACE
sed -ie 's/#    build_tools_version = "25.0.1",/    build_tools_version = "24.0.3",/g' WORKSPACE
sed -ie 's/#    path = "<PATH_TO_SDK>",/    path = "android-sdk-linux")/g' WORKSPACE

sed -ie 's/#android_ndk_repository(/android_ndk_repository(/g' WORKSPACE
sed -ie 's/#    name="androidndk",/    name="androidndk",/g' WORKSPACE
sed -ie 's/#    path="<PATH_TO_NDK>",/    path="android-ndk-r12b",/g' WORKSPACE
sed -ie 's/#    api_level=14)/    api_level=21)/g' WORKSPACE



echo "#########################################################"
echo "6.    "
echo "#########################################################"


