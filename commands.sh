#!/bin/bash


sudo ip netns add blue-ns
sudo ip netns add green-ns
sudo ip link add br0 type bridge

sudo ip link add veth-blue-ns type veth peer name veth-blue-br
sudo ip link add veth-green-ns type veth peer name veth-green-br

sudo ip link set veth-blue-ns netns blue-ns
sudo ip link set veth-green-ns netns green-ns
sudo ip link set veth-blue-br master br0
sudo ip link set veth-green-br master br0

sudo ip addr add 10.0.1.1/24 dev br0
sudo ip link set dev br0 up
sudo ip link set dev veth-blue-br up
sudo ip link set dev veth-green-br up

sudo ip netns exec blue-ns ip addr add 10.0.1.11/24 dev veth-blue-ns
sudo ip netns exec blue-ns ip link set dev veth-blue-ns up
sudo ip netns exec blue-ns ip link set dev lo up

sudo ip netns exec green-ns ip addr add 10.0.1.12/24 dev veth-green-ns
sudo ip netns exec green-ns ip link set dev veth-green-ns up
sudo ip netns exec green-ns ip link set dev lo up


sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv4.conf.all.forwarding=1
sudo sysctl -w net.bridge.bridge-nf-call-iptables=0


sudo ip netns exec blue-ns ping -c 2 10.0.1.12

sudo iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -j MASQUERADE


sudo iptables --append FORWARD --in-interface br0 --jump ACCEPT
sudo iptables --append FORWARD --out-interface br0 --jump ACCEPT


sudo ip netns exec blue-ns ip route add default via 10.0.1.1
sudo ip netns exec green-ns ip route add default via 10.0.1.1

sudo ip netns exec blue-ns ping -c 2 8.8.8.8
