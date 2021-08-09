provider "aws" {
    region = "us-west-2"
}

resource "aws_vpc" "mydemo" {
    cidr_block          = "10.1.0.0/16"
    tags = {
        Name = "mydemo"
    }
}

resource "aws_subnet" "public_cidr1" {
    vpc_id              = aws_vpc.mydemo.id
    availability_zone   = "us-west-2a"
    cidr_block          = "10.1.1.0/24"
}

resource "aws_subnet" "public_cidr2" {
    vpc_id              = aws_vpc.mydemo.id
    availability_zone   = "us-west-2b"
    cidr_block          = "10.1.2.0/24"
}

resource "aws_subnet" "private_cidr1" {
    vpc_id              = aws_vpc.mydemo.id
    availability_zone   = "us-west-2a"
    cidr_block          = "10.1.3.0/24"
}

resource "aws_subnet" "private_cidr2" {
    vpc_id              = aws_vpc.mydemo.id
    availability_zone   = "us-west-2b"
    cidr_block          = "10.1.4.0/24"
}

resource "aws_internet_gateway" "internet_gw" {
    vpc_id = aws_vpc.mydemo.id

    tags = {
        Name = "mydemo"
    }
}

resource "aws_nat_gateway" "ngw1" {
    allocation_id   = aws_eip.eip1.id
    subnet_id       = aws_subnet.public_cidr1.id
}

resource "aws_nat_gateway" "ngw2" {
    allocation_id   = aws_eip.eip2.id
    subnet_id       = aws_subnet.public_cidr2.id
}

resource "aws_eip" "eip1" {
    vpc = true
}

resource "aws_eip" "eip2" {
    vpc = true
}

resource "aws_route_table" "pub_route_table" {
    vpc_id = aws_vpc.mydemo.id 

    route = [
        {
            cidr_block                  = "0.0.0.0/0"
            gateway_id                  = aws_internet_gateway.internet_gw.id 
            destination_prefix_list_id  = ""
            egress_only_gateway_id      = ""
            instance_id                 = ""
            ipv6_cidr_block             = ""
            nat_gateway_id              = ""
            network_interface_id        = ""
            transit_gateway_id          = ""
            vpc_endpoint_id             = ""
            vpc_peering_connection_id   = ""
            carrier_gateway_id          = ""
            local_gateway_id            = ""
        },

    ]
}

resource "aws_route_table_association" "assoc1" {
    subnet_id       = aws_subnet.public_cidr1.id 
    route_table_id  = aws_route_table.pub_route_table.id 
}

resource "aws_route_table_association" "assoc2" {
    subnet_id       = aws_subnet.public_cidr2.id 
    route_table_id  = aws_route_table.pub_route_table.id 
}

resource "aws_route_table" "priv_route_table1" {
    vpc_id = aws_vpc.mydemo.id 

    route = [
        {
            cidr_block                  = "0.0.0.0/0"
            gateway_id                  = ""
            destination_prefix_list_id  = ""
            egress_only_gateway_id      = ""
            instance_id                 = ""
            ipv6_cidr_block             = ""
            nat_gateway_id              = aws_nat_gateway.ngw1.id
            network_interface_id        = ""
            transit_gateway_id          = ""
            vpc_endpoint_id             = ""
            vpc_peering_connection_id   = ""
            carrier_gateway_id          = ""
            local_gateway_id            = ""
        },

    ]
}

resource "aws_route_table" "priv_route_table2" {
    vpc_id = aws_vpc.mydemo.id 

    route = [
        {
            cidr_block                  = "0.0.0.0/0"
            gateway_id                  = ""
            destination_prefix_list_id  = ""
            egress_only_gateway_id      = ""
            instance_id                 = ""
            ipv6_cidr_block             = ""
            nat_gateway_id              = aws_nat_gateway.ngw2.id
            network_interface_id        = ""
            transit_gateway_id          = ""
            vpc_endpoint_id             = ""
            vpc_peering_connection_id   = ""
            carrier_gateway_id          = ""
            local_gateway_id            = ""
        },

    ]
}