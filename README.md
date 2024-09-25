# In this tutorial, we will learn how to

1. Create network namespaces (blue-ns and green-ns).
2. Connect them using veth pairs and a bridge.
3. Set up IP addresses and ensure communication between namespaces.
4. Configure NAT and routing to provide internet access for the namespaces.

## 1. Create Namespaces

We'll create two namespaces: `blue-ns` and `green-ns`.

```bash
sudo ip netns add blue-ns
sudo ip netns add green-ns
```

## 2. Add Virtual Devices and Cables

Next, we create a bridge (br0) and two veth pairs to connect the namespaces to the bridge.

```bash
sudo ip link add br0 type bridge
sudo ip link add veth-blue-ns type veth peer name veth-blue-br
sudo ip link add veth-green-ns type veth peer name veth-green-br
```

## 3. Connect Namespaces and Bridge with Virtual Cables

Attach the veth interfaces to the namespaces and connect the other ends to the bridge.

```bash
# Attach veth interfaces to namespaces
sudo ip link set veth-blue-ns netns blue-ns
sudo ip link set veth-green-ns netns green-ns

# Attach the peer interfaces to the bridge
sudo ip link set veth-blue-br master br0
sudo ip link set veth-green-br master br0
```

## 4. Set IP Addresses and Bring Interfaces Up (Host Space)

Configure the bridge interface and bring it up, along with the veth interfaces on the host machine.

```bash
# Set IP address to the bridge and bring it up
sudo ip addr add 10.0.1.1/24 dev br0
sudo ip link set dev br0 up

# Bring up the veth interfaces on the host
sudo ip link set dev veth-blue-br up
sudo ip link set dev veth-green-br up

```

## 5. Set IP Addresses in Namespaces and Bring Interfaces Up

Now, configure IP addresses and enable the interfaces inside each namespace.

```bash
# Blue namespace configuration
sudo ip netns exec blue-ns ip addr add 10.0.1.11/24 dev veth-blue-ns
sudo ip netns exec blue-ns ip link set dev veth-blue-ns up
sudo ip netns exec blue-ns ip link set dev lo up

# Green namespace configuration
sudo ip netns exec green-ns ip addr add 10.0.1.12/24 dev veth-green-ns
sudo ip netns exec green-ns ip link set dev veth-green-ns up
sudo ip netns exec green-ns ip link set dev lo up
```

## 6. Enable IP Forwarding and NAT

Enable IP forwarding on the host machine so traffic can pass between the namespaces and the outside world.

```bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv4.conf.all.forwarding=1
sudo sysctl -w net.bridge.bridge-nf-call-iptables=0
```

## 7. Test Namespace-to-Namespace Connectivity

Verify that the blue-ns namespace can ping green-ns.

```bash
sudo ip netns exec blue-ns ping -c 2 10.0.1.12
sudo ip netns exec green-ns ping -c 2 10.0.1.11

```

---

## Configuring Internet Access for Namespaces

To allow internet access, we need to configure NAT (Network Address Translation) using iptables and add appropriate routes in each namespace.

## 1. Configure NAT with iptables

Since the namespaces use private IP addresses, we need to enable NAT so that outgoing traffic can reach the internet using the host's public IP.

```bash
sudo iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -j MASQUERADE
```

## 2. Allow Traffic Through the Bridge

Allow all traffic to pass through the br0 interface without restrictions:

```bash
sudo iptables --append FORWARD --in-interface br0 --jump ACCEPT
sudo iptables --append FORWARD --out-interface br0 --jump ACCEPT
```

## 3. Add Default Routes for Internet Access

Add default routes in both namespaces to use the bridge (10.0.1.1) as the gateway to the internet.

```bash
sudo ip netns exec blue-ns ip route add default via 10.0.1.1
sudo ip netns exec green-ns ip route add default via 10.0.1.1
```

### 4. Test Internet Access

Test the internet connection by pinging a public IP (Google's DNS 8.8.8.8) from both namespaces:

```bash
# Test internet access from blue-ns
sudo ip netns exec blue-ns ping -c 2 8.8.8.8

# Test internet access from green-ns
sudo ip netns exec green-ns ping -c 2 8.8.8.8
```

If the pings are successful, the namespaces have internet access.
