package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

func runCommand(root string, runMake bool, path string, releaseBranch string, release string, artifactBucket string, args []string) {
	if runMake == true {
		// Add a specific target
		args[1] = args[1] + path
		command := exec.Command("make", args...)
		output, err := command.CombinedOutput()
		if err != nil {
			log.Fatalf("There was an error running make: %v. Make output:\n%v", err, string(output))
		}
		fmt.Printf("Output of the make command for %v:\n %v", path, string(output))
		// Remove the target name from the build args
		args[1] = root + "/projects/"
		if path != "coredns/coredns" {
			command = exec.Command("bash", root+"/release/lib/create_final_dir.sh", releaseBranch, release, artifactBucket, path)
			output, err = command.CombinedOutput()
			if err != nil {
				log.Fatalf("There was an error running the create_final_dir script: %v. Output:\n%v", err, string(output))
			}
			fmt.Printf("Output of the create_final_dir script for %v:\n %v", path, string(output))
			command = exec.Command("/bin/bash", "-c", "mv " + root + "/projects/" + path + "/_output/tar/*" + " /logs/artifacts")
			output, err = command.CombinedOutput()
			if err != nil {
				log.Fatalf("There was an error running mv: %v. Output:\n%v", err, string(output))
			}
			fmt.Printf("Successfully moved artifacts to /logs/artifacts directory for %v.\n", path)
		}
	}
}

func main() {
	gitRootOutput, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		log.Fatalf("There was an error running the git command: %v", err)
	}
	gitRoot := strings.Fields(string(gitRootOutput))[0]
	kubernetesChanged := false
	coreDnsChanged := false
	cniPluginsChanged := false
	iamAuthChanged := false
	etcdChanged := false
	gitDiffCommand := []string{"git", "-C", gitRoot, "diff", "--name-only", "HEAD^", "HEAD"}
	fmt.Println("\n", strings.Join(gitDiffCommand, " "))

	gitDiffOutput, err := exec.Command("git", gitDiffCommand[1:]...).Output()
	filesChanged := strings.Fields(string(gitDiffOutput))
	for _, file := range filesChanged {
		if strings.Contains(file, "kubernetes/kubernetes") {
			kubernetesChanged = true
		}
		if strings.Contains(file, "coredns/coredns") {
			coreDnsChanged = true
		}
		if strings.Contains(file, "containernetworking/plugins") {
			cniPluginsChanged = true
		}
		if strings.Contains(file, "kubernetes-sigs/aws-iam-authenticator") {
			iamAuthChanged = true
		}
		if strings.Contains(file, "etcd-io/etcd") {
			etcdChanged = true
		}
		if file == "Makefile" {
			kubernetesChanged = true
			coreDnsChanged = true
			cniPluginsChanged = true
			iamAuthChanged = true
			etcdChanged = true
		}
	}
	buildArg := []string{"-C", gitRoot + "/projects/", os.Args[1],
		"RELEASE_BRANCH=" + os.Args[2], "RELEASE=" + os.Args[3],
		"DEVELOPMENT=" + os.Args[4], "AWS_REGION=" + os.Args[5],
		"AWS_ACCOUNT_ID=" + os.Args[6], "BASE_IMAGE=" + os.Args[7],
		"IMAGE_REPO=" + os.Args[8], "IMAGE_TAG='$(GIT_TAG)-$(PULL_BASE_SHA)'"}
	kubeBuildArg := []string{"-C", gitRoot + "/projects/", os.Args[1],
		"RELEASE_BRANCH=" + os.Args[2], "RELEASE=" + os.Args[3],
		"DEVELOPMENT=" + os.Args[4], "AWS_REGION=" + os.Args[5],
		"AWS_ACCOUNT_ID=" + os.Args[6], "GO_RUNNER_IMAGE=" + os.Args[9],
		"KUBE_PROXY_BASE_IMAGE=" + os.Args[10], "IMAGE_TAG='$(GIT_TAG)-$(PULL_BASE_SHA)'"}
	runCommand(gitRoot, cniPluginsChanged, "containernetworking/plugins", os.Args[2], os.Args[3], os.Args[11], buildArg)
	runCommand(gitRoot, iamAuthChanged, "kubernetes-sigs/aws-iam-authenticator", os.Args[2], os.Args[3], os.Args[11], buildArg)
	runCommand(gitRoot, coreDnsChanged, "coredns/coredns", os.Args[2], os.Args[3], os.Args[11], buildArg)
	runCommand(gitRoot, etcdChanged, "coredns/coredns", os.Args[2], os.Args[3], os.Args[11], buildArg)
	runCommand(gitRoot, kubernetesChanged, "kubernetes/kubernetes", os.Args[2], os.Args[3], os.Args[11], kubeBuildArg)
}
