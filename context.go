package main

import (
	"context"
	// "errors"
	"fmt"
	"os/exec"
	"time"
)

func forky(ctx context.Context) error {
  cmd := exec.CommandContext(ctx, "sleep","2")
  cmd.Start()
  return cmd.Wait()
}

func main() {
	// Set a context with a timeout of
	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()

	// Replace "https://golang.org/doc/gopher.png" with a valid URL for testing
	err := forky(ctx)

	if err != nil {
		fmt.Println("forky: ", err)
	}
	if ctx.Err() != nil {
		fmt.Println(ctx.Err())
	}
}

