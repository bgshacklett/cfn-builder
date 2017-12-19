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
}

type IpPermissions struct {
	FromPort uint16
	ToPort uint16
	IpProtocol string
	UserIdGroupPairs []UserIdGroupPairs
	IpRanges []IpRanges
}

type UserIdGroupPairs struct {
	GroupId string
	UserId string
}

type IpPermissionsEgress struct {
	FromPort uint16
	ToPort uint16
	IpProtocol string
	UserIdGroupPairs []UserIdGroupPairs
	IpRanges []IpRanges
}

type IpRanges struct {
	CidrIp string
}