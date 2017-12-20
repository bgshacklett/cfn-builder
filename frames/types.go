package frames


// SupportedResources array of resources we support
type SupportedResources []SupportedResource

// SupportedResource supported resource details
type SupportedResource struct {
	// User defined description associated with the resource.
	Description string `min:"1" type:"string"`

	// The logical name of the resource specified in the template.
	LogicalResourceId string `type:"string"`

	// The name or unique identifier that corresponds to a physical instance ID
	// of a resource supported by AWS CloudFormation.
	PhysicalResourceId string `type:"string"`

	// Current status of the resource.
	ResourceStatus string `type:"string" enum:"ResourceStatus"`

	// Success/failure message associated with the resource.
	ResourceStatusReason string `type:"string"`

	// Type of resource. (For more information, go to  AWS Resource Types Reference
	// (http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)
	// in the AWS CloudFormation User Guide.)
	ResourceType string `min:"1" type:"string"`

	// Unique identifier of the stack.
	StackId string `type:"string"`

	// The name associated with the stack.
	StackName string `type:"string"`

}