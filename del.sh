#!/bin/bash

sudo ip netns del blue-ns
sudo ip netns del green-ns
sudo ip link del br0