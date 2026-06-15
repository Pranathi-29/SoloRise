import SwiftUI

// Falling light streak particle — like Image 1
struct ParticleBackground: View {
    @State private var particles: [Particle] = []
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep purple-black base
                LinearGradient(
                    colors: [
                        Color(hex: "#07050F"),
                        Color(hex: "#0F0820"),
                        Color(hex: "#07050F")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Particles
                ForEach(particles) { p in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(p.color)
                        .frame(width: p.width, height: p.length)
                        .opacity(p.opacity)
                        .blur(radius: p.blur)
                        .position(x: p.x, y: p.y)
                }
            }
            .onAppear {
                spawnParticles(in: geo.size)
            }
            .onReceive(timer) { _ in
                updateParticles(in: geo.size)
            }
        }
        .ignoresSafeArea()
    }

    private func spawnParticles(in size: CGSize) {
        particles = (0..<22).map { _ in
            Particle.random(in: size, initialSpawn: true)
        }
    }

    private func updateParticles(in size: CGSize) {
        for i in particles.indices {
            particles[i].y += particles[i].speed
            particles[i].opacity = min(particles[i].opacity + 0.01, particles[i].maxOpacity)

            // Reset when off screen
            if particles[i].y > size.height + 100 {
                particles[i] = Particle.random(in: size, initialSpawn: false)
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var length: CGFloat
    var width: CGFloat
    var speed: CGFloat
    var opacity: Double
    var maxOpacity: Double
    var blur: CGFloat
    var color: Color

    static func random(in size: CGSize, initialSpawn: Bool) -> Particle {
        let colors: [Color] = [
            Color(hex: "#A78BFF"),  // purple
            Color(hex: "#C084FC"),  // violet
            Color(hex: "#7C3AED"),  // deep purple
            Color(hex: "#FF6EB4"),  // pink
            Color(hex: "#E0AAFF"),  // light purple
        ]
        let startY: CGFloat = initialSpawn
            ? CGFloat.random(in: -200...size.height)
            : CGFloat.random(in: -200...(-20))

        return Particle(
            x: CGFloat.random(in: 0...size.width),
            y: startY,
            length: CGFloat.random(in: 20...120),
            width: CGFloat.random(in: 0.8...1.8),
            speed: CGFloat.random(in: 0.6...2.0),
            opacity: 0,
            maxOpacity: Double.random(in: 0.05...0.18),
            blur: CGFloat.random(in: 0...1.5),
            color: colors.randomElement()!
        )
    }
}
