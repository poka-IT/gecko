#!/bin/bash

for test_file in $(ls integration_test/scenarios/); do
    testName=$(echo $test_file | awk -F '.' '{print $1}')
    ./integration_test/launch_test.sh $testName || break
done