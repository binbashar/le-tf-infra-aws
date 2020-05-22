#!/bin/bash
aws_security_viz -f /aws-security-viz/aws-security-viz.png
aws_security_viz -f /aws-security-viz/aws.json --renderer navigator
mv navigator.html /aws-security-viz