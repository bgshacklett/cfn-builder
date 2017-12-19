package main

import (
	"github.com/bgshacklett/extropy/cfn"
	"github.com/bgshacklett/extropy/ui/command"
	"github.com/urfave/cli"
	"os"
	"fmt"
)

func main() {

	app := cli.NewApp()
	app.Name = "extropy"
	app.Usage = "Reduce entropy by updating a CloudFormation template from live resources."

	app.Commands = []cli.Command{
		{
			Name:  "get-updated-template",
			Usage: "Update a Security Groups template.",

			Flags: []cli.Flag{

				cli.StringFlag{
					Name:  "path, p",
					Usage: "The path to the template",
				},

				cli.StringFlag{
					Name:  "type, t",
					Usage: "The type of template",
				},

				cli.StringFlag{
					Name:  "stack-name, s",
					Usage: "The name of the associated Stack",
				},

				cli.StringFlag{
					Name:  "region, r",
					Usage: "The region where the associated Stack resides",
				},
			},

			Action: func(c *cli.Context) error {
				if err := command.GetUpdatedTemplate(
					c.String("path"),
					c.String("stack-name"),
					c.String("region"),
					os.Stdout,
					cfn.DefaultUpdateStrategy,
				); err != nil {
					fmt.Println(err)
				}
				return nil
			},
		},
	}

	app.Run(os.Args)
}
