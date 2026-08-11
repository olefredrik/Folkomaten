/*
Copyright © 2026 ANTONIO RODRIGUEZ <kontakt@antoniorodriguez.no>
*/
package cmd

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"

	fzf "github.com/junegunn/fzf/src"
	"github.com/spf13/cobra"
)

// searchCmd represents the search command
var searchCmd = &cobra.Command{
	Use:   "search",
	Short: "Search users in the Folkomaten test database",
	Long: `Search users in the Folkomaten test database using fzf.

	You can copy information of the selected user to the clipboard by pressing Enter and then choose what to copy`,
	Run: func(cmd *cobra.Command, args []string) {
		getTestUsers()
	},
}

func init() {
	rootCmd.AddCommand(searchCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// searchCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// searchCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

func getTestUsers() {
	filePath := filepath.Join("..", "Sources", "FolkomatenKit", "Resources", "testbrukere.txt")
	content, err := os.ReadFile(filePath)
	clipboardCmd := detectClipboardCmd()

	if err != nil {
		fmt.Println("Error reading file:", err)
		return
	}

	selected := startFzf(content)

	if selected == "" {
		fmt.Println("No selection made")
		return
	}

	value := readInput(selected)

	err = copyToClipboard(value, clipboardCmd)

	if err != nil {
		fmt.Printf("Clipboard failed. Value: %s\n", value)
	} else {
		fmt.Printf("Copied: %s\n", value)
	}
}

func detectClipboardCmd() string {
	clipboardCmd := "pbcopy"

	switch runtime.GOOS {
	case "linux":
		clipboardCmd = "xclip -selection clipboard"
	case "windows":
		clipboardCmd = "clip"
	}

	return clipboardCmd
}

func readInput(selected string) string {
	reader := bufio.NewReader(os.Stdin)
	fmt.Print("Copy (f)nr, (n)ame, or (a)ll? ")
	choice, _ := reader.ReadString('\n')
	choice = strings.TrimSpace(strings.ToLower(choice))

	fields := strings.Split(selected, ",")

	if len(fields) < 2 {
		fmt.Fprintf(os.Stderr, "Invalid line format: %s\n", selected)
		return ""
	}

	var value string
	switch choice {
	case "f":
		value = fields[0]
	case "n":
		value = fields[1]
	case "a":
		value = selected
	default:
		fmt.Println("Invalid choice, copying all")
		value = selected
	}

	return value

}

func copyToClipboard(value, cmd string) error {
	parts := strings.Fields(cmd)
	c := exec.Command(parts[0], parts[1:]...)
	stdin, err := c.StdinPipe()

	if err != nil {
		return err
	}

	go func() {
		io.WriteString(stdin, value)
		stdin.Close()
	}()

	return c.Run()
}

func startFzf(content []byte) string {
	wg := sync.WaitGroup{}
	inputChan := make(chan string)
	go func() {
		contentLines := strings.Split(string(content), "\n")
		for _, user := range contentLines {
			if user != "" {
				inputChan <- user
			}
		}
		close(inputChan)
	}()

	var selected string
	outputChan := make(chan string)
	wg.Go(func() {
		for s := range outputChan {
			selected = s
		}
	})

	exit := func(code int, err error) {
		if err != nil {
			fmt.Fprintln(os.Stderr, err.Error())
		}
		os.Exit(code)
	}

	options, err := fzf.ParseOptions(
		true,
		[]string{
			"--reverse", "--border", "--height=40%",
			"--header", "Press Enter to select, then choose what to copy\n\n",
		},
	)

	if err != nil {
		exit(fzf.ExitError, err)
	}

	options.Input = inputChan
	options.Output = outputChan
	code, err := fzf.Run(options)
	close(outputChan)
	wg.Wait()

	if code != 0 || err != nil {
		exit(code, err)
	}

	return selected
}
