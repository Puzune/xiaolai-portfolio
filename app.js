const PORTFOLIO = window.PORTFOLIO;
const ASSET_VERSION = PORTFOLIO.assetVersion || "";
const assetById = new Map(PORTFOLIO.assets.map((item) => [item.id, item]));
const projectGrid = document.querySelector("#project-grid");
const projectDetail = document.querySelector("#project-detail");
const galleryGrid = document.querySelector("#gallery-grid");
const galleryFilters = document.querySelector("#gallery-filters");
const lightbox = document.querySelector("#lightbox");
const lightboxImage = document.querySelector("#lightbox-image");
const lightboxCaption = document.querySelector("#lightbox-caption");

document.querySelector("#project-count").textContent = PORTFOLIO.projects.length;
document.querySelector("#asset-count").textContent = PORTFOLIO.assets.length;

function getAsset(id) {
  const item = assetById.get(id);
  if (!item) {
    throw new Error(`Missing portfolio asset: ${id}`);
  }
  return item;
}

function assetUrl(src) {
  if (!src || !ASSET_VERSION) return src;
  return `${src}${src.includes("?") ? "&" : "?"}v=${encodeURIComponent(ASSET_VERSION)}`;
}

function tagList(tags) {
  return tags.map((tag) => `<span>${tag}</span>`).join("");
}

function renderProjects() {
  projectGrid.innerHTML = PORTFOLIO.projects
    .map((project) => {
      const cover = getAsset(project.cover);
      return `
        <article class="project-card" data-project="${project.id}">
          <button class="project-trigger" type="button" aria-label="查看 ${project.title}">
            <img src="${assetUrl(cover.thumb)}" alt="${project.title}" loading="lazy" />
            <span class="project-index">${project.year}</span>
          </button>
          <div class="project-card-copy">
            <p>${project.type}</p>
            <h3>${project.title}</h3>
            <div class="tag-row">${tagList(project.tags)}</div>
          </div>
        </article>
      `;
    })
    .join("");

  projectGrid.querySelectorAll(".project-card").forEach((card) => {
    card.addEventListener("click", () => {
      renderProjectDetail(card.dataset.project, true);
    });
  });
}

function renderProjectDetail(projectId, shouldScroll = false) {
  const project = PORTFOLIO.projects.find((item) => item.id === projectId) || PORTFOLIO.projects[0];
  const cover = getAsset(project.cover);
  const coverLarge = assetUrl(cover.large);
  const gallery = project.images.map(getAsset);
  const hasCoverThumb = gallery.some((item) => item.id === cover.id);

  projectDetail.innerHTML = `
    <div class="detail-media">
      <img class="detail-main-image" src="${coverLarge}" alt="${project.title}" loading="lazy" decoding="async" />
    </div>
    <div class="detail-copy">
      <p class="eyebrow">${project.type} / ${project.year}</p>
      <h2>${project.title}</h2>
      <p>${project.summary}</p>
      <div class="tag-row">${tagList(project.tags)}</div>
      <div class="mini-gallery">
        ${gallery
          .map((item, index) => {
            const itemLarge = assetUrl(item.large);
            const itemThumb = assetUrl(item.thumb);
            const isActive = item.id === cover.id || (!hasCoverThumb && index === 0);
            return `
              <button type="button" class="mini-thumb ${isActive ? "is-active" : ""}" data-large="${itemLarge}" data-title="${item.title}" aria-label="展示 ${item.title}" aria-pressed="${isActive ? "true" : "false"}">
                <img src="${itemThumb}" alt="${item.title}" loading="lazy" />
              </button>
            `;
          })
          .join("")}
      </div>
    </div>
  `;

  projectGrid.querySelectorAll(".project-card").forEach((card) => {
    card.classList.toggle("is-active", card.dataset.project === project.id);
  });

  const mainImage = projectDetail.querySelector(".detail-main-image");
  projectDetail.querySelectorAll(".mini-thumb").forEach((button) => {
    button.addEventListener("click", () => {
      mainImage.src = button.dataset.large;
      mainImage.alt = button.dataset.title;
      projectDetail.querySelectorAll(".mini-thumb").forEach((item) => {
        const isSelected = item === button;
        item.classList.toggle("is-active", isSelected);
        item.setAttribute("aria-pressed", isSelected ? "true" : "false");
      });
    });
  });

  if (shouldScroll) {
    projectDetail.scrollIntoView({ behavior: "smooth", block: "start" });
  }
}

function renderFilters() {
  galleryFilters.innerHTML = PORTFOLIO.filters
    .map(
      (filter) => `
        <button type="button" class="gallery-filter-button ${filter.id === "all" ? "is-active" : ""}" data-filter="${filter.id}">
          ${filter.label}
        </button>
      `,
    )
    .join("");

  galleryFilters.querySelectorAll("button").forEach((button) => {
    button.addEventListener("click", () => {
      galleryFilters.querySelectorAll("button").forEach((item) => item.classList.remove("is-active"));
      button.classList.add("is-active");
      renderGallery(button.dataset.filter);
    });
  });
}

function renderGallery(activeFilter = "all") {
  const items = PORTFOLIO.assets.filter((item) => activeFilter === "all" || item.tags.includes(activeFilter));
  galleryGrid.innerHTML = items
    .map((item) => {
      const itemLarge = assetUrl(item.large);
      const itemThumb = assetUrl(item.thumb);
      return `
        <button class="gallery-item" type="button" data-image="${itemLarge}" data-title="${item.title}">
          <img src="${itemThumb}" alt="${item.title}" loading="lazy" />
          <span>
            <strong>${item.title}</strong>
            <em>${item.type}</em>
          </span>
        </button>
      `;
    })
    .join("");

  galleryGrid.querySelectorAll(".gallery-item").forEach((item) => {
    item.addEventListener("click", () => openLightbox(item.dataset.image, item.dataset.title));
  });
}

function openLightbox(src, title) {
  lightboxImage.src = src;
  lightboxImage.alt = title;
  lightboxCaption.textContent = title;
  lightbox.setAttribute("aria-hidden", "false");
  document.body.classList.add("no-scroll");
}

function closeLightbox() {
  lightbox.setAttribute("aria-hidden", "true");
  document.body.classList.remove("no-scroll");
  lightboxImage.removeAttribute("src");
  lightboxImage.alt = "";
}

document.querySelector(".lightbox-close").addEventListener("click", closeLightbox);
lightbox.addEventListener("click", (event) => {
  if (event.target === lightbox) closeLightbox();
});
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") closeLightbox();
});

renderProjects();
renderProjectDetail(PORTFOLIO.projects[0].id);
renderFilters();
renderGallery();
