const PORTFOLIO = window.PORTFOLIO;
const ASSET_VERSION = PORTFOLIO.assetVersion || "";
const assetById = new Map(PORTFOLIO.assets.map((item) => [item.id, item]));
const projectGrid = document.querySelector("#project-grid");
const projectDetail = document.querySelector("#project-detail");
const archiveGrid = document.querySelector("#archive-grid");
const archiveFilters = document.querySelector("#archive-filters");
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

  projectDetail.innerHTML = `
    <div class="detail-media">
      <button class="image-button" type="button" data-image="${coverLarge}" data-title="${project.title}">
        <img src="${coverLarge}" alt="${project.title}" loading="lazy" />
      </button>
    </div>
    <div class="detail-copy">
      <p class="eyebrow">${project.type} / ${project.year}</p>
      <h2>${project.title}</h2>
      <p>${project.summary}</p>
      <div class="tag-row">${tagList(project.tags)}</div>
      <div class="mini-gallery">
        ${gallery
          .map((item) => {
            const itemLarge = assetUrl(item.large);
            const itemThumb = assetUrl(item.thumb);
            return `
              <button type="button" class="mini-thumb" data-image="${itemLarge}" data-title="${item.title}">
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

  projectDetail.querySelectorAll("[data-image]").forEach((button) => {
    button.addEventListener("click", () => openLightbox(button.dataset.image, button.dataset.title));
  });

  if (shouldScroll) {
    projectDetail.scrollIntoView({ behavior: "smooth", block: "start" });
  }
}

function renderFilters() {
  archiveFilters.innerHTML = PORTFOLIO.filters
    .map(
      (filter) => `
        <button type="button" class="filter-button ${filter.id === "all" ? "is-active" : ""}" data-filter="${filter.id}">
          ${filter.label}
        </button>
      `,
    )
    .join("");

  archiveFilters.querySelectorAll("button").forEach((button) => {
    button.addEventListener("click", () => {
      archiveFilters.querySelectorAll("button").forEach((item) => item.classList.remove("is-active"));
      button.classList.add("is-active");
      renderArchive(button.dataset.filter);
    });
  });
}

function renderArchive(activeFilter = "all") {
  const items = PORTFOLIO.assets.filter((item) => activeFilter === "all" || item.tags.includes(activeFilter));
  archiveGrid.innerHTML = items
    .map((item) => {
      const itemLarge = assetUrl(item.large);
      const itemThumb = assetUrl(item.thumb);
      return `
        <button class="archive-item" type="button" data-image="${itemLarge}" data-title="${item.title}">
          <img src="${itemThumb}" alt="${item.title}" loading="lazy" />
          <span>
            <strong>${item.title}</strong>
            <em>${item.type}</em>
          </span>
        </button>
      `;
    })
    .join("");

  archiveGrid.querySelectorAll(".archive-item").forEach((item) => {
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
renderArchive();
