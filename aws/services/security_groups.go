package services

type SG struct{
	Description string
	GroupId string
	GroupName string
	IpPermissions []IpPermissions
	IpPermissionsEgress []IpPermissionsEgress
	OwnerId string
	Tags []Tags
	VpcId string
	PrefixListIds string
}

type IpPermissions struct {
	FromPort int
	ToPort int
	IpProtocol string
	UserIdGroupPairs []UserIdGroupPairs
	IpRanges []IpRanges
	Ipv6Ranges []Ipv6Ranges
}

type UserIdGroupPairs struct {
	GroupId string
	UserId string
}

type IpPermissionsEgress struct {
	FromPort int
	ToPort int
	IpProtocol string
	UserIdGroupPairs []UserIdGroupPairs
	IpRanges []IpRanges
}

type IpRanges struct {
	CidrIp string
}

type Ipv6Ranges struct {
	CidrIpv6 string
}