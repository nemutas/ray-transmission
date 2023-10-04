import * as THREE from 'three'
import { three } from './core/Three'
import fragmentShader from './glsl/fragmentShader.glsl'
import vertexShader from './glsl/vertexShader.glsl'

export class Canvas {
  private screen!: THREE.Mesh<THREE.PlaneGeometry, THREE.ShaderMaterial>

  constructor(canvas: HTMLCanvasElement) {
    this.loadCubeTexture().then((texture) => {
      this.init(canvas)
      this.screen = this.createScreen(texture)
      three.animation(this.anime)
    })
  }

  private async loadCubeTexture() {
    const loader = new THREE.CubeTextureLoader()
    loader.setPath(import.meta.env.BASE_URL + 'images/')
    const texture = await loader.loadAsync(['px.jpg', 'nx.jpg', 'py.jpg', 'ny.jpg', 'pz.jpg', 'nz.jpg'])
    texture.colorSpace = THREE.LinearSRGBColorSpace
    return texture
  }

  private init(canvas: HTMLCanvasElement) {
    three.setup(canvas)
    three.scene.background = new THREE.Color('#0f0f0f')
    three.camera.position.z = 3
    three.controls.dampingFactor = 0.15
    three.controls.enableDamping = true
    // three.scene.add(new THREE.AxesHelper(0.5))
  }

  private createScreen(texture: THREE.CubeTexture) {
    const geometry = new THREE.PlaneGeometry(2, 2)
    const material = new THREE.ShaderMaterial({
      uniforms: {
        tEnv: { value: texture },
        uCameraPosition: { value: three.camera.position },
        uProjectionMatrixInverse: { value: three.camera.projectionMatrixInverse },
        uViewMatrixInverse: { value: three.camera.matrixWorld },
      },
      vertexShader,
      fragmentShader,
      transparent: true,
    })
    const mesh = new THREE.Mesh(geometry, material)
    three.scene.add(mesh)
    return mesh
  }

  private anime = () => {
    three.controls.update()

    const unifroms = this.screen.material.uniforms
    unifroms.uProjectionMatrixInverse.value = three.camera.projectionMatrixInverse
    unifroms.uCameraPosition.value = three.camera.position
    unifroms.uViewMatrixInverse.value = three.camera.matrixWorld

    three.render()
  }

  dispose() {
    three.dispose()
  }
}
