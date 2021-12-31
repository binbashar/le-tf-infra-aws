resource "kubernetes_namespace" "monitoring" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "monitoring"
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "certmanager" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "certmanager"
  }
}

resource "kubernetes_namespace" "externaldns" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "externaldns"
  }
}

resource "kubernetes_namespace" "vault" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "vault"
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "argocd"
  }
}

resource "kubernetes_namespace" "gatus" {
  metadata {
    labels = {
      environment                        = var.environment
      "goldilocks.fairwinds.com/enabled" = "true"
    }

    name = "gatus"
  }
}

resource "kubernetes_namespace" "velero" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "velero"
  }
}
