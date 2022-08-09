#!/usr/bin/env bats

setup_file() {
    docker build . -t bashofmann/neuvector-image-scan-action
}

@test "docker daemon not reachable" {
    run docker run --rm -e SCANNER_REGISTRY=https://index.docker.io/ -e SCANNER_REPOSITORY=library/debian -e SCANNER_TAG=11.0 bashofmann/neuvector-image-scan-action
    echo "Status $status"
    echo "Output"
    echo -e $output
    [ "$status" -eq 125 ]
    [[ "$output" =~ "Cannot connect to the Docker daemon" ]]
}

@test "scan image with vulnerabilities but don't fail" {
    run docker run --rm -e SCANNER_REGISTRY=https://index.docker.io/ -e SCANNER_REPOSITORY=library/debian -e SCANNER_TAG=11.0 -v /var/run/docker.sock:/var/run/docker.sock bashofmann/neuvector-image-scan-action
    echo "Status $status"
    echo "Output"
    echo -e $output
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Pass the criteria check" ]]
}

@test "scan image with vulnerabilities and high severity fail" {
    run docker run --rm -e HIGH_VUL_TO_FAIL=1 -e SCANNER_REGISTRY=https://index.docker.io/ -e SCANNER_REPOSITORY=library/debian -e SCANNER_TAG=11.0 -v /var/run/docker.sock:/var/run/docker.sock bashofmann/neuvector-image-scan-action
    echo "Status $status"
    echo "Output"
    echo -e $output
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Fail due to high vulnerabilities found exceeds the criteria" ]]
}

@test "scan image with vulnerabilities and medium severity fail" {
    run docker run --rm -e MEDIUM_VUL_TO_FAIL=1 -e SCANNER_REGISTRY=https://index.docker.io/ -e SCANNER_REPOSITORY=library/debian -e SCANNER_TAG=11.0 -v /var/run/docker.sock:/var/run/docker.sock bashofmann/neuvector-image-scan-action
    echo "Status $status"
    echo "Output"
    echo -e $output
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Fail due to medium vulnerabilities found exceeds the criteria" ]]
}

@test "scan image with vulnerabilities and specific CVE fail" {
    run docker run --rm -e VUL_NAMES_TO_FAIL=invalid,CVE-2020-16156 -e SCANNER_REGISTRY=https://index.docker.io/ -e SCANNER_REPOSITORY=library/debian -e SCANNER_TAG=11.0 -v /var/run/docker.sock:/var/run/docker.sock bashofmann/neuvector-image-scan-action
    echo "Status $status"
    echo "Output"
    echo -e $output
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Fail due to found specific named vulnerabilities" ]]
}

@test "scan image with json output" {
    run docker run --rm -e OUTPUT=json -e SCANNER_REGISTRY=https://index.docker.io/ -e SCANNER_REPOSITORY=library/debian -e SCANNER_TAG=11.0 -v /var/run/docker.sock:/var/run/docker.sock bashofmann/neuvector-image-scan-action
    echo "Status $status"
    echo "Output"
    echo -e $output
    [ "$status" -eq 0 ]
    [[ "$output" =~ '"image_id": "a178460bae579ffbbf8805d8ba8e47adbe96f693098c85bf309b79547d076c21"' ]]
}

@test "scan image with csv output" {
    run docker run --rm -e OUTPUT=csv -e SCANNER_REGISTRY=https://index.docker.io/ -e SCANNER_REPOSITORY=library/debian -e SCANNER_TAG=11.0 -v /var/run/docker.sock:/var/run/docker.sock bashofmann/neuvector-image-scan-action
    echo "Status $status"
    echo "Output"
    echo -e $output
    [ "$status" -eq 0 ]
    [[ "$output" =~ '"severity"' ]]
}