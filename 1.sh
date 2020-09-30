#!/bin/bash
gcloud auth revoke --all

while [[ -z "$(gcloud config get-value core/account)" ]]; 
do echo "waiting login" && sleep 2; 
done

while [[ -z "$(gcloud config get-value project)" ]]; 
do echo "waiting project" && sleep 2; 
done


export IMAGE_FAMILY="tf-1-14-cpu"
export ZONE="us-west1-b"
export INSTANCE_NAME="tf-tensorboard-1"
export INSTANCE_TYPE="n1-standard-4"
gcloud compute instances create "${INSTANCE_NAME}" \
        --zone="${ZONE}" \
        --image-family="${IMAGE_FAMILY}" \
        --image-project=deeplearning-platform-release \
        --machine-type="${INSTANCE_TYPE}" \
        --boot-disk-size=200GB \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --metadata="proxy-mode=project_editors"


# training-data-analyst/quests/dei

# # ---- TODO ---------
# model = Sequential()
# model.add(layers.Dense(8, input_dim = input_size))
# model.add(layers.Dense(1, activation = 'sigmoid'))
# model.compile(optimizer='sgd', loss='mse')
# model.fit(train_data, train_labels, batch_size=32, epochs=10)


# ---- TODO ---------
# limited_model = Sequential()
# limited_model.add(layers.Dense(8, input_dim = input_size))
# limited_model.add(layers.Dense(1, activation = 'sigmoid'))
# limited_model.compile(optimizer='sgd', loss='mse')
# limited_model.fit(limited_train_data, limited_train_labels, batch_size=32, epochs=10)

export GCP_PROJECT=$(gcloud config list project --format "value(core.project)")
export MODEL_BUCKET="gs://$GCP_PROJECT"
export MODEL_NAME='complete_model'
export LIM_MODEL_NAME='limited_model'
export VERSION_NAME='v1'
export REGION='us-central1'

gsutil mb gs://$GCP_PROJECT

gsutil cp -r ./saved_model $MODEL_BUCKET
gsutil cp -r ./saved_limited_model $MODEL_BUCKET

gcloud ai-platform models create $MODEL_NAME --regions $REGION

# gcloud ai-platform versions create $VERSION_NAME \
# --model=$MODEL_NAME \
# --framework='Tensorflow' \
# --runtime-version=1.15 \
# --origin=$MODEL_BUCKET/saved_model/my_model \
# --staging-bucket=$MODEL_BUCKET \
# --python-version=3.7 \
# --project=$GCP_PROJECT

gcloud ai-platform models create $LIM_MODEL_NAME --regions $REGION

# gcloud ai-platform versions create $VERSION_NAME \
# --model=$LIM_MODEL_NAME \
# --framework='Tensorflow' \
# --runtime-version=1.15 \
# --origin=$MODEL_BUCKET/saved_limited_model/my_limited_model \
# --staging-bucket=$MODEL_BUCKET \
# --python-version=3.7 \
# --project=$GCP_PROJECT

gcloud ai-platform versions create $VERSION_NAME \
--model=$MODEL_NAME \
--framework='Tensorflow' \
--runtime-version=2.1 \
--origin=$MODEL_BUCKET/saved_model/my_model \
--staging-bucket=$MODEL_BUCKET \
--python-version=3.7 \
--project=$GCP_PROJECT

gcloud ai-platform versions create $VERSION_NAME \
--model=$LIM_MODEL_NAME \
--framework='Tensorflow' \
--runtime-version=2.1 \
--origin=$MODEL_BUCKET/saved_limited_model/my_limited_model \
--staging-bucket=$MODEL_BUCKET \
--python-version=3.7 \
--project=$GCP_PROJECT


gcloud beta compute ssh --zone "us-west1-b" "tf-tensorboard-1" --quiet --command="sudo mkdir -p /home/jupyter/training-data-analyst/quests/dei && sudo chmod 777 /home/jupyter/training-data-analyst/quests/dei"
gcloud beta compute ssh --zone "us-west1-b" "tf-tensorboard-1" --quiet --command="cd /home/jupyter/training-data-analyst/quests/dei && wget https://files.consumerfinance.gov/hmda-historic-loan-data/hmda_2017_ny_all-records_labels.zip && unzip hmda_2017_ny_all-records_labels.zip"

# gcloud beta compute ssh --zone "us-west1-b" "tf-tensorboard-1" --quiet --command="gsutil cp $MODEL_BUCKET /home/jupyter/training-data-analyst/quests/dei/"

gcloud beta compute scp --zone "us-west1-b" --quiet --recurse saved_model/ saved_limited_model/ tf-tensorboard-1:/home/jupyter/training-data-analyst/quests/dei/



