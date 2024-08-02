#!/usr/bin/env bash

current_dir="$(pwd)"

echo "Current directory $current_dir"

PROD_IMAGE_NAME="${REGISTRY}/${REGISTRY_IMAGE_NAME}-prod"
NONPROD_IMAGE_NAME="${REGISTRY}/${REGISTRY_IMAGE_NAME}-nonprod"

IMAGE_TAG=${IMAGE_TAG:-"$1"}

# ----------------------------------

sign_image() {
	local image_name=$1
	local tag=$2

	# ----------------------------------

	local image_url="${image_name}:${tag}"

	# ----------------------------------

	# Command to get the key URIs
	output=$(cosign pkcs11-tool list-keys-uris \
		--module-path /usr/local/lib/Garantir/GRS/libgrsp11.so \
		--slot-id 1)

	echo "cosign pkcs11-tool list-keys-uris output $output"

	# Filter for lines containing 'URI' and get the actual URI
	pkcs11_uri=$(echo "$output" | grep 'URI:' | awk -F'URI:' '{print $2}' | xargs)

	if [[ -z "$pkcs11_uri" ]]; then
		pkcs11_uri="${GARASIGN_EAL_CODE_SIGNING_URI}"

		if [[ -z "$pkcs11_uri" ]]; then
			echo "No PKCS11 URI found"
			exit 1
		fi
	fi

	echo "PKCS11 URI $pkcs11_uri"

	# ----------------------------------

	# Run the garasign command and save its output
	output=$(/opt/Garantir/bin/garasign listkeys)

	echo "garasign listkeys output $output"

	# Extract the line containing "public key name"
	key_name_line=$(echo "$output" | grep 'public key name')

	# Extract the key name from the line
	public_key_name=$(echo "$key_name_line" | awk -F'public key name ' '{print $2}' | xargs)

	if [[ -z "$public_key_name" ]]; then
		public_key_name="${GARASIGN_EAL_PUBLIC_KEY_NAME}"

		if [[ -z "$public_key_name" ]]; then
			echo "No public key found"
			exit 1
		fi
	fi

	echo "public key name $public_key_name"

	/opt/Garantir/bin/garasign export --key "$public_key_name" --outputDirectory "${current_dir}"

	if [[ ! -f "${current_dir}/${public_key_name}.pem.chain" ]]; then
		echo "No public key chain found"
		exit 1
	fi

	if [[ ! -f "${current_dir}/${public_key_name}.pem.pub.key" ]]; then
		echo "No public key found"
		exit 1
	fi

	# ----------------------------------

	digest=$(docker inspect --format='{{index .RepoDigests 0}}' "${image_url}")

	if [[ -z "$digest" ]]; then
		echo "No digest found"
		exit 1
	fi

	echo "digest $digest"

	echo "Signing image ${digest}"

	output=$(cosign sign --key "$pkcs11_uri" --cert-chain "${current_dir}/$public_key_name.pem.chain" "${digest}")

	if [[ -z "$output" ]]; then
		echo "Image ${digest} signed successfully"
	fi

	echo "Verifying image ${digest}"

	output=$(cosign verify --key "${current_dir}/$public_key_name".pem.pub.key "${digest}")

	if [[ -n "$output" ]]; then
		echo "Image ${digest} verified successfully"
	fi
}

build_and_push_image() {
	local target_image_name=$1
	local tag=$2
	local compose_file
	compose_file="$(find . -regex '\.\/docker-compose\(-prod\)?.ya?ml')"

	# ----------------------------------

	local image_url="${target_image_name}:${tag}"

	# ----------------------------------

	echo "Building image ${image_url}"

	if [ -f "$compose_file" ]; then
		docker-compose -f "$compose_file" build --progress plain
	else
		echo "No docker-compose file found"
		exit 1
	fi

	echo "Tagging image ${image_url}"

	docker tag "${REGISTRY_IMAGE_NAME}" "${image_url}"

	echo "Pushing image ${image_url}"

	if ! docker push "${image_url}"; then
		echo "Failed to push image ${image_url}"
		exit 1
	fi

	echo "Image ${image_url} pushed successfully"

	sign_image "${target_image_name}" "${tag}"
}

# ----------------------------------

echo "${REGISTRY_PASSWORD}" | docker login -u "${REGISTRY_USER}" --password-stdin "${REGISTRY_HOST}"

case "$TRAVIS_BRANCH" in
  development)
    build_and_push_image "${NONPROD_IMAGE_NAME}" "${IMAGE_TAG}"
    ;;

  *)
    build_and_push_image "${PROD_IMAGE_NAME}" "${IMAGE_TAG}"
    ;;
esac
