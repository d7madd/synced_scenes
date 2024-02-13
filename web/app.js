new Vue({
  el: "#app",
  data: {
    showMenu: false,
    state: {
      search: localStorage.getItem("synched_scenes_devtool:search") || "",
      scenes: [],
      selected: "nan",
      duration: 0,
      actors: 0,
      objects: 0,
      favs: [],
      limit: 100,
      stoping: false,
      setScrollPos: 0,
      showFavs: false,
    },
    scenes: null,
  },
  computed: {
    formatScenes() {
      if (this.state.showFavs) {
        return this.state.scenes
          .filter((item) => {
            return item.name.toLowerCase().includes(this.state.search.toLowerCase()) && this.state.favs.includes(item.name);
          })
          .slice(0, this.state.limit);
      }
      return this.state.scenes
        .filter((item) => {
          return item.name.toLowerCase().includes(this.state.search.toLowerCase());
        })
        .slice(0, this.state.limit);
    },
  },
  updated() {
    this.$nextTick(() => {
      if (!this.$refs.scenes) return;
      this.$refs.scenes.scrollTop = this.state.setScrollPos;
    });
  },
  mounted() {
    this.fetchScenes();
    window.addEventListener("message", (event) => {
      const data = event.data;
      if (!data || !data.source === "synched_scenes_devtool") return;
      if (data.open === true) {
        this.showMenu = true;
        this.state.favs = data.favs;
        this.state.currentScene = data.current;
      } else {
        this.showMenu = false;
      }
    });
    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape") {
        this.showMenu = false;
        this.emitNui("sync_scenes:closeMenu");
      }
    });
  },
  methods: {
    onInput(event) {
      this.state.search = event.target.value;
      localStorage.setItem("synched_scenes_devtool:search", this.state.search);
    },
    toggleFavourites() {
      this.state.showFavs = !this.state.showFavs;
    },
    async emitNui(event, data = {}) {
      const url = `https://${GetParentResourceName()}/${event}`;
      try {
        const res = await fetch(url, {
          method: "POST",
          headers: {
            "Content-Type": "application/json; charset=UTF-8",
          },
          body: JSON.stringify(data),
        }).then((res) => res.json());
        return res;
      } catch (error) {
        console.error(error);
      }
    },
    async fetchScenes() {
      const res = await this.emitNui("sync_scenes:getSynchedScenes");
      if (!res) {
        console.log("Error fetching scenes");
        return;
      }
      this.state.scenes = res.data;
    },
    async startScene(scene) {
      const res = await this.emitNui("sync_scenes:startSynchedScene", { id: scene.id });
      if (!res || !res.ok) {
        console.log(res.message || "Error starting scene");
        return;
      }
      this.state.selected = res.currentScene;
      this.state.duration = res.scene.animDur;
      this.state.actors = res.scene.actors;
      this.state.objects = res.scene.objects;
    },
    async setFav(scene) {
      if (this.state.favs.includes(scene.name)) {
        this.state.favs = this.state.favs.filter((item) => item !== scene.name);
      } else {
        this.state.favs.push(scene.name);
      }
      const res = await this.emitNui("sync_scenes:SynchedScenes:toggleFav", { favs: this.state.favs });
      if (!res.ok || !res) {
        console.log(res.message || "Error setting fav");
        return;
      }
    },
    async stopScene() {
      if (this.state.stoping) return;
      this.state.stoping = true;
      const res = await this.emitNui("sync_scenes:stopSynchedScene");
      if (res.ok) this.state.stoping = false;
    },
    handleScroll() {
      const scrollContainer = this.$refs.scenes;
      const bottomOfContainer = scrollContainer.scrollHeight - scrollContainer.scrollTop === scrollContainer.clientHeight;
      this.state.setScrollPos = scrollContainer.scrollTop;

      if (bottomOfContainer) {
        this.state.limit += 100;
      }
    },
  },
});
