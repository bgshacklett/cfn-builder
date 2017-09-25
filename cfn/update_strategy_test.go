package cfn

import (
	"encoding/json"
	"github.com/aws/aws-sdk-go/aws/arn"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/awslabs/goformation/cloudformation"
	"github.com/bgshacklett/extropy/aws"
	"github.com/stretchr/testify/assert"
	"io/ioutil"
	"testing"
)

func newTestTemplate(fileName string) (*cloudformation.Template, error) {

	template := cloudformation.NewTemplate()
	templateJson, err := ioutil.ReadFile("./tests/" + fileName)
	json.Unmarshal(templateJson, template)

	return template, err
}

func newTestSecurityGroup(fileName string) (*ec2.SecurityGroup, error) {

	securityGroup := new(ec2.SecurityGroup)
	securityGroupJson, err := ioutil.ReadFile("./tests/" + fileName)
	json.Unmarshal(securityGroupJson, securityGroup)

	return securityGroup, err
}

type testCfnMapper struct{ arn arn.ARN }

func (r *testCfnMapper) MapResource(
	region string,
	stackName string,
	resource string,
) (arn.ARN, error) {

	return arn.ARN{
			Partition: "arn",
			Service:   "svc",
			Region:    region,
			AccountID: "12345",
			Resource:  stackName + "/" + resource,
		},
		nil
}

type testSGDescriber struct{}

// DescribeResource gets information about a resource from the AWS API
func (r *testSGDescriber) DescribeResource(
	arn arn.ARN,
) (aws.Resource, error) {

	// Get a mock Security Group object.
	securityGroup, err := newTestSecurityGroup("sg_m.template")

	description := arn.String()
	groupId := "sg-xxxxxxxx"
	groupName := "GroupName"

	// Configure the object.
	securityGroup.Description = &description
	securityGroup.GroupId = &groupId
	securityGroup.GroupName = &groupName

	// Return the SG
	return securityGroup, err
}

func TestExecuteModified(t *testing.T) {

	// Create a new object to handle assertions
	assert := assert.New(t)

	fmtExecuteNoError := "Execute should not return an error."
	fmtExecuteMatchExpected := "Execute should return the expected result."

	/*
	 * Setup
	 */
	// Create instances of the original and expected templates
	orig, err := newTestTemplate("orig.template")
	assert.Nil(err, "newTestTemplate should not return an error for orig.")

	expected, err := newTestTemplate("mod_resource.template")
	assert.Nil(err, "newTestTemplate should not return an error for expected.")

	// Create instances of stubbed dependencies.
	cfnMapper := new(testCfnMapper)
	resourceDescriber := new(testSGDescriber)

	// Create an instance of the system under test.
	updateStrategy := new(DefaultUpdateStrategy)

	/*
	 * Test
	 */
	actual, err := updateStrategy.Execute(
		"us-test-1", // Region
		orig,
		"modified", // Stack Name
		cfnMapper,
		resourceDescriber,
	)

	// Ensure that the method does not throw an error.
	assert.Nil(err, fmtExecuteNoError)

	// Ensure that the actual result matches the expected result.
	assert.Equal(expected, actual, fmtExecuteMatchExpected)
	/*
	 * Teardown
	 */
}
