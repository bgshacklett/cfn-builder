package services

// SecurityGroup resource property
type SecurityGroup struct{
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

// IpPermissions resource property
type IpPermissions struct {
	FromPort int
	ToPort int
	IpProtocol string
	UserIdGroupPairs []UserIdGroupPairs
	IpRanges []IpRanges
	Ipv6Ranges []Ipv6Ranges
}

// IpPermissionsEgress resource property
type IpPermissionsEgress struct {
	FromPort int
	ToPort int
	IpProtocol string
	UserIdGroupPairs []UserIdGroupPairs
	IpRanges []IpRanges
	Ipv6Ranges []Ipv6Ranges
}

// UserIdGroupPairs resource property
type UserIdGroupPairs struct {
	GroupId string
	UserId string
}

// IpRanges resource property
type IpRanges struct {
	CidrIp string
}

// Ipv6Ranges resource property
type Ipv6Ranges struct {
	CidrIpv6 string
	Description string
}