package fabricdl

import (
	"encoding/json"
	"errors"
	"github.com/pufferpanel/pufferpanel/v3"
	"path"
)

const FabricMetadataUrl = "https://meta.fabricmc.net/v2/versions/installer"

type Fabricdl struct {
	TargetFile string
}

type FabricMetadata struct {
	Url string `json:"url"`
}

func (f *Fabricdl) Run(env pufferpanel.Environment) error {
	env.DisplayToConsole(true, "Downloading metadata from %s\n", FabricMetadataUrl)
	response, err := pufferpanel.HttpGet(FabricMetadataUrl)
	if err != nil {
		return err
	}
	defer pufferpanel.Close(response.Body)

	var metadata []FabricMetadata
	err = json.NewDecoder(response.Body).Decode(&metadata)
	if err != nil {
		return err
	}
	if len(metadata) == 0 {
		return errors.New("no metadata available from Fabric, unable to download installer")
	}

	file, err := pufferpanel.DownloadViaMaven(metadata[0].Url, env)
	if err != nil {
		return err
	}

	err = pufferpanel.CopyFile(file, path.Join(env.GetRootDirectory(), "fabric-installer.jar"))
	if err != nil {
		return err
	}

	return nil
}
