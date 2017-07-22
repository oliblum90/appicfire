# Finetune Imagenet with Tensorflow and export android app

Our workflow includes the following points:

 * Install bazel
 * Download and build Tensorflow
 * Download and finetune Inception model
 * Build .apk with new finetuned model

## Install bazel

https://bazel.build/versions/master/docs/install.html

```sh
# install dependencies
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java8-installer
sudo apt install curl
sudo apt install git

# install bazel
echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get install bazel
sudo apt-get upgrade bazel
```


## Download and build Tensorflow

https://www.tensorflow.org/install/install_sources
https://www.tensorflow.org/install/install_sources#ConfigureInstallation

```sh
# clone tensorflow and choose version (checkout branch)
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
git checkout r1.0

# install python dependencies
sudo apt-get install python-numpy python-dev python-pip python-wheel

# configure and install
./configure
bazel build --config=opt //tensorflow/tools/pip_package:build_pip_package
bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
sudo pip install /tmp/tensorflow_pkg/tensorflow-1.0.1-py2-none-any.whl
```


## Download and finetune Inception model

https://www.tensorflow.org/tutorials/image_retraining

put the images to be used for finetuning in a folder "data" of the following structure:

 * roses/rose_img_heidelberg.jpg
 * roses/red_rose.jpg
 * roses/shiny_rose.jpg
 * ...
 * tulips/t1.jpg
 * tulips/tulpis_yellow.jpg
 * ...

The format may be .jpg or .png with a size of 299 x 299

```sh
# build retrainer
bazel build tensorflow/examples/image_retraining:retrain

# retrain
bazel-bin/tensorflow/examples/image_retraining/retrain \
--image_dir data \
--how_many_training_steps 50000 \
--output_graph tensorflow/examples/android/assets/retrained_graph.pb \
--output_labels tensorflow/examples/android/assets/retrained_labels.txt
```
After a certain number of training iterations we can start to train with augmentation:

```sh
bazel-bin/tensorflow/examples/image_retraining/retrain \
--image_dir data \
--how_many_training_steps 50000 \
--output_graph tensorflow/examples/android/assets/retrained_graph_aug.pb \
--output_labels tensorflow/examples/android/assets/retrained_labels_aug.txt \
--flip_left_right True \
--random_crop 25 \
--random_scale 25 \
--random_brightness 25
```

To show the tensorboard evaluation do:

```sh
tensorboard --logdir /tmp/retrain_logs
```

## Disable automatic downloading of models

In the [BUILD](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/examples/android/BUILD) file comment the following lines out

```sh
        "@inception5h//:model_files",
        "@mobile_multibox//:model_files",
        "@stylize//:model_files",
```


## Build .apk with new finetuned model

https://www.oreilly.com/learning/tensorflow-on-android

before putting the finetuned model into the app it needs to be optimized:

```sh
bazel build tensorflow/python/tools:optimize_for_inference
bazel-bin/tensorflow/python/tools/optimize_for_inference \
--input tensorflow/examples/android/assets/retrained_graph.pb \
--output tensorflow/examples/android/assets/retrained_optimized_graph.pb \
--input_names=Mul \
--output_names=final_result
```

get Android SDK and NDK:

```sh
# get sdk
wget https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz
tar xvzf android-sdk_r24.4.1-linux.tgz -C tensorflow

# update sdk
cd tensorflow/android-sdk-linux
tools/android update sdk --no-ui

# get ndk
cd ..
wget https://dl.google.com/android/repository/android-ndk-r12b-linux-x86_64.zip
unzip android-ndk-r12b-linux-x86_64.zip -d
```
Uncommand and modify the following lines in Tensorflow [WORKSPACE](https://github.com/tensorflow/tensorflow/blob/master/WORKSPACE). To find out the build_tools_version go to "android-sdk-linux/build_tools.

```sh
android_sdk_repository(
            name = "androidsdk",
            api_level = 24,
            build_tools_version = "24.0.3",
            path = "android-sdk-linux")

android_ndk_repository(
            name="androidndk",
            path="android-ndk-r12b",
            api_level=21)
```

Edid the [TensorflowImageListener.java](https://github.com/petewarden/tensorflow_makefile/blob/master/tensorflow/examples/android/src/org/tensorflow/demo/TensorflowImageListener.java):

```sh
private static final int INPUT_SIZE = 299;
private static final int IMAGE_MEAN = 128;
private static final float IMAGE_STD = 128;
private static final String INPUT_NAME = "Mul:0";
private static final String OUTPUT_NAME = "final_result:0";

private static final String MODEL_FILE = "file:///android_asset/retrained_graph.pb";
private static final String LABEL_FILE = "file:///android_asset/retrained_labels.txt";
```

build .apk:

```sh
bazel build //tensorflow/examples/android:tensorflow_demo
```
