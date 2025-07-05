        var app = angular.module('catsvsdogs', []);
        var socket = io.connect();

        var bg1 = document.getElementById('background-stats-1');
        var bg2 = document.getElementById('background-stats-2');

        app.controller('statsCtrl', function($scope) {
            $scope.aPercent = 50;
            $scope.bPercent = 50;
            $scope.total = 0;

            var updateScores = function() {
                socket.on('scores', function(json) {
                    try {
                        var data = JSON.parse(json);
                        var a = parseInt(data.a || 0);
                        var b = parseInt(data.b || 0);

                        var percentages = getPercentages(a, b);

                        // Actualizar barras de fondo con animación
                        bg1.style.width = percentages.a + "%";
                        bg2.style.width = percentages.b + "%";

                        // Actualizar scope con animación
                        $scope.$apply(function() {
                            $scope.aPercent = percentages.a;
                            $scope.bPercent = percentages.b;
                            $scope.total = a + b;
                        });

                        // Efectos visuales adicionales
                        addVoteEffect();
                    } catch (error) {
                        console.error('Error parsing scores:', error);
                    }
                });
            };

            var addVoteEffect = function() {
                // Agregar clase de animación temporal
                const voteCounter = document.querySelector('.vote-count');
                if (voteCounter) {
                    voteCounter.style.animation = 'none';
                    setTimeout(() => {
                        voteCounter.style.animation = 'countUp 0.5s ease';
                    }, 10);
                }
            };

            var init = function() {
                document.body.classList.add('loaded');
                updateScores();
                
                // Conectar eventos de socket
                socket.on('connect', function() {
                    console.log('Connected to server');
                });

                socket.on('disconnect', function() {
                    console.log('Disconnected from server');
                });
            };

            // Inicializar cuando se reciba el primer mensaje
            socket.on('message', function(data) {
                init();
            });

            // Inicializar inmediatamente también
            init();
        });

        function getPercentages(a, b) {
            var result = {};

            if (a + b > 0) {
                result.a = Math.round(a / (a + b) * 100);
                result.b = 100 - result.a;
            } else {
                result.a = result.b = 50;
            }

            return result;
        }

        // Efectos adicionales de partículas cuando cambian los votos
        function createVoteParticle(type) {
            const particle = document.createElement('div');
            particle.style.position = 'fixed';
            particle.style.fontSize = '2rem';
            particle.style.pointerEvents = 'none';
            particle.style.zIndex = '9999';
            particle.innerHTML = type === 'cat' ? '🐱' : '🐶';
            
            const startX = Math.random() * window.innerWidth;
            particle.style.left = startX + 'px';
            particle.style.top = '0px';
            
            document.body.appendChild(particle);
            
            let position = 0;
            const animation = setInterval(() => {
                position += 5;
                particle.style.top = position + 'px';
                particle.style.opacity = 1 - (position / window.innerHeight);
                
                if (position > window.innerHeight) {
                    clearInterval(animation);
                    particle.remove();
                }
            }, 20);
        }

        // Agregar efectos de sonido (opcional)
        function playVoteSound() {
            // Solo reproducir si el usuario ha interactuado con la página
            try {
                const audioContext = new (window.AudioContext || window.webkitAudioContext)();
                const oscillator = audioContext.createOscillator();
                const gainNode = audioContext.createGain();
                
                oscillator.connect(gainNode);
                gainNode.connect(audioContext.destination);
                
                oscillator.frequency.value = 800;
                gainNode.gain.setValueAtTime(0.1, audioContext.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1);
                
                oscillator.start(audioContext.currentTime);
                oscillator.stop(audioContext.currentTime + 0.1);
            } catch (error) {
                // Ignorar errores de audio
            }
        }